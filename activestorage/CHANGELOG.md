*   Add `xhr` object to direct-upload:error event so that server generated error messages are accessible.

    Before:
    ```javascript
    addEventListener("direct-upload:error", event => {
      event.preventDefault()
      const { id, error } = event.detail
      const element = document.getElementById(`direct-upload-${id}`)
      element.classList.add("direct-upload--error")
      element.setAttribute("title", error)
    })
    ```

    After:
    ```javascript
    addEventListener("direct-upload:error", event => {
      event.preventDefault()
      const { id, error, xhr } = event.detail
      const element = document.getElementById(`direct-upload-${id}`)
      const errorMessage = xhr.response['error'] // Example: File size must be less than 100MB
      element.classList.add("direct-upload--error")
      element.setAttribute("title", errorMessage)
    })
    ```

    Fixes #49104

    *Sean Abrahams*

*   Allow accepting `service` as a proc as well in `has_one_attached` and `has_many_attached`.

    *Yogesh Khater*

Please check [7-1-stable](https://github.com/rails/rails/blob/7-1-stable/activestorage/CHANGELOG.md) for previous changes.
