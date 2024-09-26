*   Add `active_storage_direct_uploads_controller` load hook

    Issue #34961

    Allows users to restrict direct uploads with their own authentication and/or rate limiting.

    ```ruby
    ActiveSupport.on_load :active_storage_direct_uploads_controller do
      before_action :authenticate_user!
      rate_limit to: 10, within: 3.minutes
    end
    ```

    *juanvqz*

*   Deprecate `ActiveStorage::Service::AzureStorageService`.

    *zzak*

*   Improve `ActiveStorage::Filename#sanitized` method to handle special characters more effectively.
    Replace the characters `"*?<>` with `-` if they exist in the Filename to match the Filename convention of Win OS.

    *Luong Viet Dung(Martin)*

*   Improve InvariableError, UnpreviewableError and UnrepresentableError message.

    Include Blob ID and content_type in the messages.

    *Petrik de Heus*

*   Mark proxied files as `immutable` in their Cache-Control header

    *Nate Matykiewicz*


Please check [7-2-stable](https://github.com/rails/rails/blob/7-2-stable/activestorage/CHANGELOG.md) for previous changes.
