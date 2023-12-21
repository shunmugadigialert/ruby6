import { EditorState, Plugin } from "prosemirror-state"
import { Decoration, DecorationSet, EditorView } from "prosemirror-view"
import { Schema, DOMParser, DOMSerializer } from "prosemirror-model"
import { schema } from "prosemirror-schema-basic"
import { addListNodes } from "prosemirror-schema-list"
import { exampleSetup } from "prosemirror-example-setup"
import { AttachmentUpload } from "@rails/actiontext"

let placeholderPlugin = new Plugin({
  state: {
    init() { return DecorationSet.empty },
    apply(tr, set) {
      // Adjust decoration positions to changes made by the transaction
      set = set.map(tr.mapping, tr.doc)
      // See if the transaction adds or removes any placeholders
      let action = tr.getMeta(this)
      if (action && action.add) {
        let widget = document.createElement("placeholder")
        let deco = Decoration.widget(action.add.pos, widget, {id: action.add.id})
        set = set.add(tr.doc, [deco])
      } else if (action && action.remove) {
        set = set.remove(set.find(null, null,
                                  spec => spec.id == action.remove.id))
      }
      return set
    }
  },
  props: {
    decorations(state) { return this.getState(state) }
  }
})

function findPlaceholder(state, id) {
  let decos = placeholderPlugin.getState(state)
  let found = decos.find(null, null, spec => spec.id == id)
  return found.length ? found[0].from : null
}

function getHTMLStringFromProsemirror ({ schema, doc: { content } }) {
  const fragment = DOMSerializer.fromSchema(schema).serializeFragment(content)
  const div = document.createElement("div")
  div.appendChild(fragment)
  return div.innerHTML
}

const actionTextNodes = schema.spec.nodes
  .update("figure", {
    group: "block",
    draggable: true,
    content: "inline",
    attrs: {
      actionTextAttachment: {default: null}
    },

    parseDOM: [{
      tag: "figure[data-action-text-attachment]",
      getAttrs: (dom) => {
        const attrs = {}
        const json = dom.getAttribute("data-action-text-attachment") || "{}"

        try {
          const actionTextAttachment = JSON.parse(json)

          Object.assign(attrs, { actionTextAttachment })
        } catch {
        }

        return attrs
      }
    }],

    toDOM: ({ attrs: { actionTextAttachment } }) => {
      const attrs = { contenteditable: false }

      if (actionTextAttachment) {
        Object.assign(attrs, { "data-action-text-attachment": JSON.stringify(actionTextAttachment) })
      }

      if (actionTextAttachment.content) {
        const figure = document.createElement("figure")
        for (const [name, value] of Object.entries(attrs)) {
          figure.setAttribute(name, value)
        }
        figure.innerHTML = actionTextAttachment.content

        return figure
      } else {
        return ["figure", attrs, 0]
      }
    }
  })

const actionTextSchema = new Schema({
  nodes: actionTextNodes,
  marks: schema.spec.marks
})

addEventListener("DOMContentLoaded", () => {
  for (const target of document.querySelectorAll("[data-action-text-editor=prosemirror]")) {
    const { blobUrlTemplate, directUploadUrl } = target.dataset

    const input =
      target.nextElementSibling instanceof HTMLInputElement ?
        target.nextElementSibling :
        null
    const content = Object.assign(document.createElement("div"), {
      innerHTML: input.value
    })

    const view = new EditorView(target, {
      state: EditorState.create({
        doc: DOMParser.fromSchema(actionTextSchema).parse(content),
        plugins: [
          ...exampleSetup({ schema: actionTextSchema }),
          placeholderPlugin,
          new Plugin({
            view(editorView) {
              return {
                update(view, prevState) {
                  input.value = getHTMLStringFromProsemirror(view.state)
                }
              }
            }
          })
        ]
      })
    })
    view.dom.setAttribute("role", "textbox")

    function startImageUpload(view, file) {
      // A fresh object to act as the ID for this upload
      let id = {}

      // Replace the selection with a placeholder
      let tr = view.state.tr
      if (!tr.selection.empty) tr.deleteSelection()
      tr.setMeta(placeholderPlugin, {add: {id, pos: tr.selection.from}})
      view.dispatch(tr)

      uploadFile(file).then(({ url, actionTextAttachment }) => {
        let pos = findPlaceholder(view.state, id)
        // If the content around the placeholder has been deleted, drop
        // the image
        if (pos == null) return
        // Otherwise, insert it at the placeholder's position, and remove
        // the placeholder
        const figure =
        view.dispatch(view.state.tr
          .replaceWith(pos, pos, actionTextSchema.nodes.figure.create({actionTextAttachment}, [
            actionTextSchema.nodes.image.create({src: url})
          ]))
          .setMeta(placeholderPlugin, {remove: {id}}))
      }, () => {
        // On failure, just clean up the placeholder
        view.dispatch(tr.setMeta(placeholderPlugin, {remove: {id}}))
      })
    }

    function uploadFile(file) {
      const delegate = {
        blobUrlTemplate,
        directUploadUrl,

        uploadDidComplete({ url, ...actionTextAttachment }) {
          return { url, actionTextAttachment }
        }
      }

      const attachmentUpload = new AttachmentUpload(delegate, file)
      return attachmentUpload.start()
    }

    addEventListener("input", ({ target }) => {
      if (view.state.selection.$from.parent.inlineContent && target.files.length) {
        for (const file of target.files) {
          startImageUpload(view, file)
        }

        view.focus()

        target.value = target.defaultValue
      }
    })

    addEventListener("click", ({ target }) => {
      if (target.matches(`[data-trix-action~="x-attach"]`)) {
        const toolbar = target.closest("trix-toolbar")
        const template = target.querySelector("template")
        const actionTextAttachment = {
          ...JSON.parse(template.getAttribute("data-action-text-attachment")),
          content: template.innerHTML
        }

        if (view.state.selection.$from.parent.inlineContent) {
          const tr = view.state.tr
          if (!tr.selection.empty) tr.deleteSelection()
          const pos = tr.selection.from
          const figure = actionTextSchema.nodes.figure.create({actionTextAttachment})

          view.dispatch(view.state.tr.insert(pos, figure))
        }
      }
    })
  }
})
