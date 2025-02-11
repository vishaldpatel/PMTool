defmodule PmToolWeb.NowAndNextTasksComponent do
  use PmToolWeb, :live_component

  alias Phoenix.LiveView.JS
  alias PmTool.Tasks

  def render(assigns) do
    ~H"""
    <div class="mr-2 text-left w-80 flex-shrink-0 droppable_task_list">
      <button
        title="Create New Task"
        class="font-bold rounded"
        phx-click={
          JS.toggle_class("hidden", to: "#edit-#{@new_task_id}")
          |> JS.toggle_class("hidden", to: "#new_task_helper")
        }
      >
        <svg
          class="h-6 w-6 text-cyan-500 hover:text-cyan-400"
          fill="none"
          viewBox="0 0 24 24"
          stroke="currentColor"
        >
          <path
            stroke-linecap="round"
            stroke-linejoin="round"
            stroke-width="2"
            d="M9 13h6m-3-3v6m5 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"
          />
        </svg>
      </button>

      <button
        title="Split Now and Next Tasks"
        class="font-bold rounded"
        phx-click="separate_now_and_next_tasks"
      >
        <svg
          class="h-6 w-6 text-red-500 hover:text-red-400"
          <svg
          viewBox="0 0 24 24"
          width="24"
          height="24"
          xmlns="http://www.w3.org/2000/svg"
          fill="none"
          stroke="currentColor"
          stroke-width="2"
          stroke-linecap="round"
          stroke-linejoin="round"
        >
          <rect x="3" y="3" width="18" height="18" rx="2" ry="2" />
          <rect x="7" y="7" width="3" height="9" /> <rect x="14" y="7" width="3" height="5" />
        </svg>
      </button>
      <span class="font-semibold uppercase align-top ml-1 text-gray-400">Now+Next</span>

      <form id="now_task_options" style="display: none;" phx-submit="task_actions">
        <button
          title="Delete Selected Tasks"
          name="action"
          value="delete_tasks"
          class="font-bold rounded"
        >
          <svg
            class="h-6 w-6 text-red-500 hover:text-red-400"
            width="24"
            height="24"
            viewBox="0 0 24 24"
            stroke-width="2"
            stroke="currentColor"
            fill="none"
            stroke-linecap="round"
            stroke-linejoin="round"
          >
            <path stroke="none" d="M0 0h24v24H0z" /> <line x1="4" y1="7" x2="20" y2="7" />
            <line x1="10" y1="11" x2="10" y2="17" /> <line x1="14" y1="11" x2="14" y2="17" />
            <path d="M5 7l1 12a2 2 0 0 0 2 2h8a2 2 0 0 0 2 -2l1 -12" />
            <path d="M9 7v-3a1 1 0 0 1 1 -1h4a1 1 0 0 1 1 1v3" />
          </svg>
        </button>
        <button
          title="Move Selected Tasks To The Later Pile"
          name="action"
          value="move_to_later"
          class="font-bold rounded"
        >
          <svg
            class="h-6 w-6 text-sky-500 hover:text-sky-400"
            width="24"
            height="24"
            viewBox="0 0 24 24"
            stroke-width="2"
            stroke="currentColor"
            fill="none"
            stroke-linecap="round"
            stroke-linejoin="round"
          >
            <path stroke="none" d="M0 0h24v24H0z" /> <path d="M10 4l2 1l2 -1m-2 -2v6.5l3 1.72" />
            <path d="M10 4l2 1l2 -1m-2 -2v6.5l3 1.72" transform="rotate(60 12 12)" />
            <path d="M10 4l2 1l2 -1m-2 -2v6.5l3 1.72" transform="rotate(120 12 12)" />
            <path d="M10 4l2 1l2 -1m-2 -2v6.5l3 1.72" transform="rotate(180 12 12)" />
            <path d="M10 4l2 1l2 -1m-2 -2v6.5l3 1.72" transform="rotate(240 12 12)" />
            <path d="M10 4l2 1l2 -1m-2 -2v6.5l3 1.72" transform="rotate(300 12 12)" />
          </svg>
        </button>
      </form>
      <%= if length(@now_tasks) > 0 do %>
        <ul phx-hook="Sortable" id={@id}>
          <%= for task <- @now_tasks do %>
            <.live_component
              module={PmToolWeb.TaskComponent}
              draggable={
                task.status == "Unstarted" or (task.is_milestone == true and is_nil(task.due_date))
              }
              id={"task-#{task.slug}#{@timestamp}"}
              task={task}
              show_task={if @open_tasks[task.slug], do: "hidden", else: "flex"}
              show_task_edit={if @open_tasks[task.slug], do: "flex", else: "hidden"}
              actions={true}
              current_user={@current_user}
            />
          <% end %>
        </ul>
      <% else %>
        {create_task_help_svg(assigns)}
      <% end %>
      <%= if @next_tasks do %>
        <%= for {index, current_tasks} <- @next_tasks do %>
          <%= if index == 1 do %>
            <div class="font-bold text-gray-400 uppercase text-xs my-1 text-right">
              Next Week
            </div>
          <% else %>
            <div class="font-bold text-gray-400 uppercase text-xs my-1 text-right">
              {index} Weeks
            </div>
          <% end %>
          <ul phx-hook="Sortable" id={"#{@id}-group-#{index}"}>
            <%= for task <- current_tasks do %>
              <.live_component
                module={PmToolWeb.TaskComponent}
                id={"task-#{task.slug}#{@timestamp}"}
                draggable={true}
                task={task}
                show_task={if @open_tasks[task.slug], do: "hidden", else: "flex"}
                show_task_edit={if @open_tasks[task.slug], do: "flex", else: "hidden"}
                current_user={@current_user}
              />
            <% end %>
          </ul>
        <% end %>
      <% end %>
      <.live_component
        module={PmToolWeb.TaskComponent}
        id={@new_task_id}
        current_user={@current_user}
        current_team={@current_team}
      />
    </div>
    """
  end

  def mount(socket) do
    {:ok, socket}
  end

  def update(assigns, socket) do
    socket =
      socket
      |> assign(assigns)
      |> maybe_get_current_task()

    {:ok, socket}
  end

  defp maybe_get_current_task(socket) do
    case socket.assigns["slug"] do
      nil ->
        assign(socket, task: nil)

      slug ->
        task = Tasks.get_task_by_slug!(slug)
        assign(socket, task: task)
    end
  end

  defp create_task_help_svg(assigns) do
    ~H"""
    <svg
      id="new_task_helper"
      viewBox="0 0 360 432"
      version="1.1"
      id="svg1"
      inkscape:version="1.4 (e7c3feb1, 2024-10-09)"
      sodipodi:docname="click here to create task.svg"
      xmlns:inkscape="http://www.inkscape.org/namespaces/inkscape"
      xmlns:sodipodi="http://sodipodi.sourceforge.net/DTD/sodipodi-0.dtd"
      xmlns="http://www.w3.org/2000/svg"
      xmlns:svg="http://www.w3.org/2000/svg"
      width="1.75in"
    >
      <sodipodi:namedview
        id="namedview1"
        pagecolor="#ffffff"
        bordercolor="#000000"
        borderopacity="0.25"
        inkscape:showpageshadow="2"
        inkscape:pageopacity="0.0"
        inkscape:pagecheckerboard="0"
        inkscape:deskcolor="#d1d1d1"
        inkscape:document-units="in"
        inkscape:zoom="0.55711443"
        inkscape:cx="404.76424"
        inkscape:cy="521.43686"
        inkscape:window-width="1280"
        inkscape:window-height="772"
        inkscape:window-x="0"
        inkscape:window-y="0"
        inkscape:window-maximized="1"
        inkscape:current-layer="g5"
      />
      <defs id="defs1" />
      <g inkscape:label="Layer 1" inkscape:groupmode="layer" id="layer1">
        <g id="g5">
          <text
            xml:space="preserve"
            style="font-style:normal;font-variant:normal;font-weight:bold;font-stretch:normal;font-size:46.6667px;font-family:'Chalkboard SE';-inkscape-font-specification:'Chalkboard SE, Bold';font-variant-ligatures:normal;font-variant-caps:normal;font-variant-numeric:normal;font-variant-east-asian:normal;text-align:start;writing-mode:lr-tb;direction:ltr;text-anchor:start;fill:#cccccc"
            x="38.348087"
            y="299.07318"
            id="text1"
            transform="rotate(-10)"
          >
            <tspan
              x="38.348087"
              y="299.07318"
              style="font-style:normal;font-variant:normal;font-weight:bold;font-stretch:normal;font-size:46.6667px;font-family:'Chalkboard SE';-inkscape-font-specification:'Chalkboard SE, Bold';font-variant-ligatures:normal;font-variant-caps:normal;font-variant-numeric:normal;font-variant-east-asian:normal;fill:#cccccc"
              id="tspan3"
              sodipodi:role="line"
            >
              click here
            </tspan>
            <tspan
              x="38.348087"
              y="357.40656"
              style="font-style:normal;font-variant:normal;font-weight:bold;font-stretch:normal;font-size:46.6667px;font-family:'Chalkboard SE';-inkscape-font-specification:'Chalkboard SE, Bold';font-variant-ligatures:normal;font-variant-caps:normal;font-variant-numeric:normal;font-variant-east-asian:normal;fill:#cccccc"
              id="tspan4"
              sodipodi:role="line"
            >
              to create a
            </tspan>
            <tspan
              x="38.348087"
              y="415.73993"
              style="font-style:normal;font-variant:normal;font-weight:bold;font-stretch:normal;font-size:46.6667px;font-family:'Chalkboard SE';-inkscape-font-specification:'Chalkboard SE, Bold';font-variant-ligatures:normal;font-variant-caps:normal;font-variant-numeric:normal;font-variant-east-asian:normal;fill:#cccccc"
              id="tspan5"
              sodipodi:role="line"
            >
              new task
            </tspan>
          </text>
          <path
            style="fill:#cccccc;stroke-width:1.23428"
            id="path5"
            d="m 148.86304,222.63853 c -8.81867,0.72138 -17.25144,-2.25522 -25.36883,-5.79467 3.47602,2.71771 -15.39966,-8.8599 -11.52545,-6.69895 2.93257,1.63573 5.54194,4.06186 8.64,5.25008 1.97084,0.75589 -3.48716,-2.56383 -5.18256,-3.92402 -2.98808,-2.3973 -6.42465,-5.55712 -9.28839,-8.12999 -8.67326,-7.49913 -16.17098,-15.91211 -22.92044,-25.55922 -7.3755,-10.88294 -13.1036,-22.77873 -17.72645,-35.39297 -5.21895,-15.83844 -6.40322,-32.73214 -7.19962,-49.451563 -0.52101,-12.86185 -0.67598,-25.72507 0.88685,-38.49819 0.83055,-7.25493 2.74718,-14.17196 5.29241,-20.86771 4.39556,-10.50057 0.63785,-6.50641 -13.99851,-15.65911 -4.64964,1.66679 -8.92978,4.46774 -13.22131,7.04893 -4.90814,3.21607 -9.47725,7.02923 -14.24507,10.48811 -3.23813,2.37878 -6.04374,5.24673 -8.68678,8.39921 -1.28604,1.33341 -2.21382,2.90457 -3.09592,4.57329 -0.5427,1.06667 -1.05996,2.14976 -1.5508904,3.24773 5.1589304,3.24188 10.1792604,6.78037 15.4767804,9.72565 0.005,0.003 0.97431,-1.10058 1.5811,-1.81347 2.17707,-2.55774 4.14872,-5.32583 6.18811,-8.02209 5.79601,-7.93037 11.40479,-16.01415 17.61975,-23.53966 2.71435,-2.23324 4.55246,-5.7459 7.55557,-7.51557 0.49529,-0.29967 2.05577,-2.95133 2.17379,-2.62641 0.6245,-0.80573 1.64331,0.95298 1.26694,0.72577 -4.90941,-2.96374 -9.65067,-6.26745 -14.476,-9.4011801 1.62084,1.4773401 3.25003,2.8820001 4.97057,4.2214001 3.86662,2.7167 7.55869,5.66826 10.88617,9.18092 2.81766,2.57244 4.77881,5.93413 6.91762,9.15703 1.07556,1.50031 2.2048,2.98884 3.50022,4.25746 0.39201,1.37505 1.10723,2.16174 1.898,3.19023 0.28034,0.41976 0.50589,0.87918 0.72381,1.34182 0,0 15.95593,8.22788 15.95593,8.22788 v 0 c -0.18903,-0.5711 -0.4131,-1.12586 -0.66013,-1.6683 -0.20904,-0.46355 -0.27971,-1.03052 -0.59891,-1.40626 -0.6087,-0.71647 -1.25237,0.15847 -1.34109,-1.71758 -0.56961,-1.92109 -2.45717,-2.91032 -3.49388,-4.53917 -2.37745,-3.13399 -4.04429,-6.90401 -7.03447,-9.45339 -3.11938,-3.69172 -6.70731,-6.86678 -10.6482,-9.38991 -1.63323,-1.41769 -3.45354,-2.40138 -4.80222,-4.18161 C 58.95883,13.543927 51.8068,3.1824569 45.57328,7.1302869 c -0.7688,0.86975 -1.20268,2.02627 -2.13355,2.73357 -2.86591,2.2634801 -4.81969,5.6793301 -7.47667,8.2289801 -5.95737,7.76533 -11.46907,15.92845 -17.48949,23.63366 -0.39498,0.47632 -4.23792,5.13027 -5.03269,6.02716 -0.15697,0.17716 -2.03886,2.14297 -2.46115,2.55792 -0.20707,0.20348 -0.86317,0.40965 -0.63834,0.58767 4.72508,3.74075 9.74496,6.98622 14.61745,10.47934 0.38035,-1.06661 0.84047,-2.09646 1.34798,-3.09324 0.86242,-1.51399 1.71549,-2.99756 2.84158,-4.29628 2.49144,-3.07406 5.21983,-5.79712 8.30021,-8.11844 4.66518,-3.51635 9.22358,-7.23533 14.10707,-10.3682 3.87817,-2.27196 8.28939,-5.78339 12.77151,-5.58461 -4.82314,-3.13779 -9.78512,-6.01968 -14.46942,-9.41338 -0.79458,-0.57566 1.03565,-0.69943 0.99741,-0.32782 -0.13864,1.34753 -1.32862,2.5692 -1.42223,3.93335 -2.38205,6.9572 -4.38521,14.05748 -5.14635,21.50531 -1.52583,12.95548 -1.21291,26.01043 -0.63711,39.03932 0.8279,16.850983 1.96581,33.887323 6.89671,49.960083 4.44277,12.75769 10.02686,24.74601 17.32938,35.76483 1.46868,2.14379 5.08107,7.49939 6.6987,9.53287 4.84908,6.09566 10.67047,11.13102 16.14769,16.46288 14.01152,12.74277 29.28235,23.80565 45.82046,31.96375 8.51121,3.4783 17.23751,6.20258 26.38435,5.79778 z"
          />
        </g>
      </g>
    </svg>
    """
  end
end
