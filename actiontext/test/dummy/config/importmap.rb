# Pin npm packages by running ./bin/importmap

pin "application", preload: true
pin "@hotwired/turbo-rails", to: "turbo.min.js", preload: true
pin "trix"
pin "@rails/actiontext", to: "actiontext.esm.js"
pin_all_from "app/javascript/editors", under: "editors"

pin "prosemirror-state", to: "https://ga.jspm.io/npm:prosemirror-state@1.4.3/dist/index.js"
pin "prosemirror-view", to: "https://ga.jspm.io/npm:prosemirror-view@1.32.7/dist/index.js"
pin "prosemirror-model", to: "https://ga.jspm.io/npm:prosemirror-model@1.19.4/dist/index.js"
pin "prosemirror-keymap", to: "https://ga.jspm.io/npm:prosemirror-keymap@1.2.2/dist/index.js"
pin "prosemirror-history", to: "https://ga.jspm.io/npm:prosemirror-history@1.3.2/dist/index.js"
pin "prosemirror-commands", to: "https://ga.jspm.io/npm:prosemirror-commands@1.5.2/dist/index.js"
pin "prosemirror-dropcursor", to: "https://ga.jspm.io/npm:prosemirror-dropcursor@1.8.1/dist/index.js"
pin "prosemirror-gapcursor", to: "https://ga.jspm.io/npm:prosemirror-gapcursor@1.3.2/dist/index.js"
pin "prosemirror-transform", to: "https://ga.jspm.io/npm:prosemirror-transform@1.8.0/dist/index.js"
pin "prosemirror-menu", to: "https://ga.jspm.io/npm:prosemirror-menu@1.2.4/dist/index.js"
pin "prosemirror-inputrules", to: "https://ga.jspm.io/npm:prosemirror-inputrules@1.3.0/dist/index.js"
pin "prosemirror-schema-basic", to: "https://ga.jspm.io/npm:prosemirror-schema-basic@1.2.2/dist/index.js"
pin "prosemirror-schema-list", to: "https://ga.jspm.io/npm:prosemirror-schema-list@1.3.0/dist/index.js"
pin "prosemirror-example-setup", to: "https://ga.jspm.io/npm:prosemirror-example-setup@1.2.2/dist/index.js"
pin "orderedmap", to: "https://ga.jspm.io/npm:orderedmap@2.1.1/dist/index.js"
pin "w3c-keyname", to: "https://ga.jspm.io/npm:w3c-keyname@2.2.8/index.js"
pin "rope-sequence", to: "https://ga.jspm.io/npm:rope-sequence@1.3.4/dist/index.js"
pin "crelt", to: "https://ga.jspm.io/npm:crelt@1.0.6/index.js"
pin "prosemirror-image-plugin", to: "https://ga.jspm.io/npm:prosemirror-image-plugin@2.9.0/dist/index.es.js"
