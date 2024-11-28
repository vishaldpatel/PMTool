defmodule PmToolWeb.TasksLive do
  use PmToolWeb, :live_view
  alias Phoenix.LiveView.JS
  alias PmTool.Tasks

  def render(assigns) do
    # Renders all the components
    # Menu on the left
    # Done Tasks if toggled
    # Current Tasks
    # Upcoming Tasks if toggled
    # Backlog Tasks if toggled

    ## Placeholder:
    ~H"""
    <div class="text-left w-80">
      <%= if @task do %>
        <.live_component module={PmToolWeb.TaskComponents} task={@task} id={"task-"<>@task.slug} expanded={true} />
      <% end %>


      <button 
        class="font-bold rounded" 
        phx-click={
          JS.toggle(to: "#edit-"<>@new_task_id)
        }>
        <svg class="h-6 w-6 text-cyan-500"  fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 13h6m-3-3v6m5 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"/>
        </svg>
      </button>

      <form id="batch_task_options" style="display: none;" phx-submit="delete_tasks">
        <button class="font-bold rounded">
          <svg class="h-6 w-6 text-red-500"  width="24" height="24" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor" fill="none" stroke-linecap="round" stroke-linejoin="round">  <path stroke="none" d="M0 0h24v24H0z"/>  <line x1="4" y1="7" x2="20" y2="7" />  <line x1="10" y1="11" x2="10" y2="17" />  <line x1="14" y1="11" x2="14" y2="17" />  <path d="M5 7l1 12a2 2 0 0 0 2 2h8a2 2 0 0 0 2 -2l1 -12" />  <path d="M9 7v-3a1 1 0 0 1 1 -1h4a1 1 0 0 1 1 1v3" /></svg> 
        </button>
      </form>

      <script>
        selected_tasks = {};
        batch_task_options = document.getElementById("batch_task_options");

        document.addEventListener("task_checkbox_clicked", (event) => {
          task_container = document.getElementById("show-task-"+event.detail.slug);
          task_container.classList.toggle('bg-yellow-100');
          task_container.classList.toggle('bg-gray-100');

          if (document.querySelectorAll('input[name="batch_task_slugs[]"]:checked').length > 0) {
            document.getElementById("batch_task_options").style.display = "inline-block";
          } else {
            document.getElementById("batch_task_options").style.display = "none";
          }

          if (event.target.checked) {
            batch_task_options.innerHTML += `<input type="hidden" name="task_slugs[]" value="${event.detail.slug}" id="chk-${event.detail.slug}">`;
          } else {
            // Remove element with id of chk-id
            document.getElementById(`chk-${event.detail.slug}`).remove();
          }
        });
      </script>

      <script>
        var _el;

        function dragEndHandler() {
          event.preventDefault();
        }

        function dropHandler(e) {
          event.preventDefault();
        }

        function dragEnterHandler(e) {
          event.preventDefault();
        }

        function dragOverHandler(e) {
          if (e.target.parentNode.getAttribute("draggable") == "true") {
            let li_node = e.target.parentNode;
            if (li_node !== _el) {
              if (isBefore(_el, li_node)) {
                li_node.parentNode.insertBefore(_el, li_node);
              } else {
                li_node.parentNode.insertBefore(_el, li_node.nextElementSibling);
              }
            }
          }
        }

        function dragStartHandler(e) {
          e.dataTransfer.effectAllowed = "move";
          e.dataTransfer.setData("text/plain", null); // Thanks to bqlou for their comment.
          _el = e.target;
        }

        function isBefore(el1, el2) {
          if (el2.parentNode === el1.parentNode)
            for (var cur = el1.previousSibling; cur && cur.nodeType !== Node.DOCUMENT_NODE; cur = cur.previousSibling)
              if (cur === el2)
                return true;
          return false;
        }
      </script>

      <%= if @tasks do %>
        <ul>
          <%= for task <- @tasks do %>
            <.live_component module={PmToolWeb.TaskComponents} id={"task-"<>task.slug} task={task} />
          <% end %>
        </ul>
      <% end %>
      <.live_component module={PmToolWeb.TaskComponents} id="new_task" current_user={@current_user} />

    </div>
    """
  end

  def mount(params, _session, socket) do
    socket =
      assign(socket, new_task_id: "new_task")
      |> maybe_get_current_task(params)
      |> maybe_get_tasks_for_current_user()
    {:ok, socket}
  end

  def handle_event("delete_tasks", params, socket) do
    current_user = socket.assigns.current_user
    task_slugs = params["task_slugs"]
    Tasks.delete_tasks_with_slugs(current_user, task_slugs)
    socket = maybe_get_tasks_for_current_user(socket)
    {:noreply, socket}
  end

  def handle_info({:new_task_created, new_task_id}, socket) do
    socket = 
      assign(socket, new_task_id: new_task_id) 
      |> maybe_get_tasks_for_current_user()
    {:noreply, socket}
  end

  defp maybe_get_current_task(socket, params) do
    case params["slug"] do
      nil -> assign(socket, task: nil)
      slug -> task = Tasks.get_task_by_slug!(slug)
              assign(socket, task: task)
    end
  end

  defp maybe_get_tasks_for_current_user(socket) do
    current_user = socket.assigns.current_user
    tasks = PmTool.Tasks.list_tasks_for(current_user)
    assign(socket, tasks: tasks)
  end
end
