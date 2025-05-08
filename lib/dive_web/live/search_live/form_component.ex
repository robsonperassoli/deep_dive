defmodule DiveWeb.SearchLive.FormComponent do
  use DiveWeb, :live_component

  alias Dive.Research

  @impl true
  def render(assigns) do
    ~H"""
    <div class="flex h-full items-center justify-center">
      <div class="w-2/3 max-w-screen-sm space-y-4">
        <hgroup>
          <h2 class="font-black text-3xl text-indigo-500">DeepDive</h2>
          <p class="italic text-sm leading-4">Explore beyond the surface.</p>
        </hgroup>

        <.form
          for={@form}
          id="topic-form"
          phx-target={@myself}
          phx-change="validate"
          phx-submit="save"
        >
          <textarea
            id={@form[:text].id}
            name={@form[:text].name}
            phx-hook="SubmitOnEnter"
            class={[
              "block w-full rounded-lg text-white focus:ring-0 sm:text-sm sm:leading-6 min-h-[6rem] bg-zinc-600",
              @form[:text].errors == [] && "border-zinc-600 focus:border-zinc-600",
              @form[:text].errors != [] && "border-rose-500 focus:border-rose-600"
            ]}
            placeholder="Type any topic you want ot know more about"
          >{Phoenix.HTML.Form.normalize_value("textarea", @form[:text].value)}</textarea>
        </.form>
      </div>
    </div>
    """
  end

  @impl true
  def update(%{topic: topic} = assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign_new(:form, fn ->
       to_form(Research.change_topic(topic))
     end)}
  end

  @impl true
  def handle_event("validate", %{"topic" => topic_params}, socket) do
    changeset = Research.change_topic(socket.assigns.topic, topic_params)
    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"topic" => topic_params}, socket) do
    case Research.create_topic(topic_params) do
      {:ok, topic} ->
        notify_parent({:saved, topic})

        {:noreply,
         socket
         |> push_patch(to: ~p"/topics/#{topic.id}")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end


  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
