*   Render `Hash` and keyword options as dasherized HTML attributes

    ```ruby
    tag.button "POST to /clicked", hx: { post: "/clicked", swap: :outerHTML, data: { json: true } }

    # => <button hx-post="/clicked" hx-swap="outerHTML" hx-data="{&quot;json&quot;:true}">POST to /clicked</button>
    ```

    *Sean Doyle*

Please check [8-0-stable](https://github.com/rails/rails/blob/8-0-stable/actionview/CHANGELOG.md) for previous changes.
