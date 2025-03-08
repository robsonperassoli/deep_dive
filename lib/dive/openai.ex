defmodule Dive.OpenAI do
  require Logger

  @api_url "https://api.openai.com"
  @chat_completions_url @api_url <> "/v1/chat/completions"

  defmodule Message do
    @derive Jason.Encoder
    defstruct [:content, :role]
  end

  def chat_completion([%Message{} | _] = messages, opts \\ []) do
    model = Keyword.get(opts, :model, "gpt-4o-mini")
    # lower temp values make the response more deterministic, good for data extraction tasks
    temperature = Keyword.get(opts, :temperature, 0.3)
    json? = Keyword.get(opts, :json, true)

    @chat_completions_url
    |> Req.post!(
      json: %{
        model: model,
        store: true,
        messages: messages,
        response_format: if(json?, do: %{"type" => "json_object"}),
        max_tokens: 12_000,
        temperature: temperature
      },
      headers: %{
        "Authorization" => "Bearer " <> api_key()
      },
      receive_timeout: 200_000,
      retry: :transient,
      max_retries: 2
    )
  end

  def api_key() do
    config()[:api_key]
  end

  def config() do
    Application.get_env(:dive, :openai)
  end
end
