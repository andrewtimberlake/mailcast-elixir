defmodule Mailcast.Templates do
  @moduledoc """
  Create and manage email templates.

  Templates content can be provided as [MJML](https://mjml.io/) or HTML/text.
  Provide `mjml` or `content`, not both. Use the returned `template_id` when
  [sending an email](https://mailcast.io/docs/api/emails/create).

  Templates created with a test API key are test-only (`test_only: true`) until a
  production key updates (promotes) them. The name is unique per domain.

  `mjml`, `content`, and `subject` can include dynamic content using the
  [template language](https://mailcast.io/docs/api/templates/language).

  ## Configuration

  See `Mailcast.Client` for `:api_key` and `:base_url`.
  """

  alias Mailcast.Client

  @doc """
  Create an email template from MJML or HTML.

  Provide `mjml` or `content`, not both.

  ## Parameters

    * `:name` - Unique name for the template on this domain (required)
    * `:mjml` - MJML source. Compiled to HTML when sending. Required unless `content` is provided
    * `:content` - HTML or plain text. Required unless `mjml` is provided
    * `:from` - Default From address used when sending if the send request omits `from`
    * `:to` - Default recipients used when sending if the send request omits `to`
    * `:subject` - Default subject used when sending if the send request omits `subject`

  ## Options

    * `:api_key` - Mailcast API key
    * `:base_url` - Mailcast API base URL

  ## Examples

      {:ok, template} =
        Mailcast.Templates.create(%{
          name: "welcome",
          mjml: "<mjml><mj-body><mj-section><mj-column><mj-text>Hello {{name}}</mj-text></mj-column></mj-section></mj-body></mjml>",
          from: "hello@example.com",
          subject: "Welcome {{name}}"
        })

  """
  def create(params, opts \\ []) do
    Client.post("/v1/templates", params, opts)
  end

  @doc """
  List email templates for the domain associated with the API token.

  Production keys only see production templates. Test keys see both test-only
  and production templates.

  ## Options

    * `:api_key` - Mailcast API key
    * `:base_url` - Mailcast API base URL

  ## Examples

      {:ok, %{"templates" => templates}} = Mailcast.Templates.list()

  """
  def list(opts \\ []) do
    Client.get("/v1/templates", opts)
  end

  @doc """
  Retrieve a single email template.

  Production keys can get a test-only template by id (so they can promote it)
  even though it is omitted from the list.

  ## Options

    * `:api_key` - Mailcast API key
    * `:base_url` - Mailcast API base URL

  ## Examples

      {:ok, template} = Mailcast.Templates.get("template_01jzqtmznaexgb9d3rpectx870")

  """
  def get(template_id, opts \\ []) when is_binary(template_id) do
    Client.get("/v1/templates/#{template_id}", opts)
  end

  @doc """
  Update an existing email template.

  Changing `mjml` recompiles the stored HTML. A production key updating a
  test-only template promotes it (`test_only` becomes `false`). A test key
  cannot update a production template (`403`).

  ## Parameters

    * `:name` - Unique name for the template on this domain
    * `:mjml` - MJML source. Do not send with `content`
    * `:content` - HTML or plain text. Do not send with `mjml`
    * `:from` - Default From address
    * `:to` - Default recipients
    * `:subject` - Default subject

  ## Options

    * `:api_key` - Mailcast API key
    * `:base_url` - Mailcast API base URL

  ## Examples

      {:ok, template} =
        Mailcast.Templates.update("template_01jzqtmznaexgb9d3rpectx870", %{
          name: "welcome-updated",
          subject: "Hi {{name}}"
        })

  """
  def update(template_id, params, opts \\ []) when is_binary(template_id) do
    Client.patch("/v1/templates/#{template_id}", params, opts)
  end

  @doc """
  Delete an email template.

  Returns `{:ok, nil}` whether or not the template existed. Test keys can only
  delete test-only templates. Production keys can only delete production
  templates. Wrong-mode deletes return `403`.

  ## Options

    * `:api_key` - Mailcast API key
    * `:base_url` - Mailcast API base URL

  ## Examples

      {:ok, nil} = Mailcast.Templates.delete("template_01jzqtmznaexgb9d3rpectx870")

  """
  def delete(template_id, opts \\ []) when is_binary(template_id) do
    Client.delete("/v1/templates/#{template_id}", opts)
  end
end
