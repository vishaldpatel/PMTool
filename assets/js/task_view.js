export default class TaskView {
  setup_batch_tasks() {
    let selected_tasks = {}
    let batch_task_options = document.getElementById("batch_task_options")

    function checkbox_clicked_handler(event) {
      let task_container = document.getElementById("show-task-"+event.detail.slug)
      task_container.classList.toggle('bg-orange-500')

      if (document.querySelectorAll('input[name="batch_task_slugs[]"]:checked').length > 0) {
        document.getElementById("batch_task_options").style.display = "inline-block"
      } else {
        document.getElementById("batch_task_options").style.display = "none"
      }

      if (event.target.checked) {
        batch_task_options.innerHTML += `<input type="hidden" name="task_slugs[]" value="${event.detail.slug}" id="chk-${event.detail.slug}">`
      } else {
        // Remove element with id of chk-id
        document.getElementById(`chk-${event.detail.slug}`).remove()
      }
    }

    document.addEventListener("task_checkbox_clicked", checkbox_clicked_handler)
  }

  setup_drag_and_drop() {
    var _move_element = null
    var _task_slug = null
    var _above_slug = null
    var _noq = 0
    var _move_target = null
    var _target_parent_node = null

    function dragEndHandler(event) {
      event.preventDefault()
      console.log("dragEndHandler")
    }

    function dropHandler(event) {
      event.preventDefault()
      move_target(event.target.parentNode)
      let move_task_event = new CustomEvent("move_task", {detail: {active_task_slug: _task_slug, affected_task_slug: _above_slug, action: _noq}})
      window.dispatchEvent(move_task_event)
    }

    function move_target(target) {
      if (target !== _move_element) {
        if (isBefore(_move_element, target)) {
          target.parentNode.insertBefore(_move_element, target)
          _task_slug = _move_element.querySelector(".task_slug").value
          _above_slug = target.querySelector(".task_slug").value
          _noq = "move_above"
        } else {
          target.parentNode.insertBefore(_move_element, target.nextElementSibling)
          _task_slug = _move_element.querySelector(".task_slug").value
          _above_slug = target.querySelector(".task_slug").value
          _noq = "move_below"
        }
      }
    }

    function unset_placeholder(target) {
      target.innerHTML = _move_target.innerHTML
      target.id = _move_target.id
      reset_drag_handlers_for_placeholder(target)
    }

    function set_placeholder(target) {
      // Copy target into _move_target
      _move_target = target.cloneNode(true)
      _target_parent_node = target.parentNode
      let div = document.createElement("div")

      target.id = "placeholder-for-move"
      remove_drag_handlers_for_placeholder(target)
      target.innerHTML = ""

      target.appendChild(div)
      div.classList.add("align-top", "w-full", "pl-1", "pr-1", "cursor-pointer", "border", "text-left", "text-md", "rounded", "bold", "bg-gray-600", "text-gray-100", "inline-block")
      div.innerHTML = "&nbsp;"
    }

    function dragLeaveHandler(e) {
      if (e.target.parentNode.getAttribute("draggable") == "true") {
        console.log("dragLeaveHandler")
        unset_placeholder(e.target.parentNode)
      }
    }

    function dragEnterHandler(e) {
      e.preventDefault()
      console.log("dragEnterHandler")
      if (e.target.parentNode.getAttribute("draggable") == "true") {
        set_placeholder(e.target.parentNode)
      }
    }

    function dragOverHandler(e) {
      e.preventDefault()
    }

    function dragStartHandler(e) {
      e.dataTransfer.effectAllowed = "move"
      e.dataTransfer.setData("text/plain", null) // Thanks to bqlou for their comment.
      _move_element = e.target
    }

    function isBefore(el1, el2) {
      if ((el2 !== null) && (el2.parentNode === el1.parentNode))
        for (var cur = el1.previousSibling; cur && cur.nodeType !== Node.DOCUMENT_NODE; cur = cur.previousSibling)
          if (cur === el2)
            return true
      return false
    }

    function remove_drag_handlers_for_placeholder(target) {
      target.removeEventListener("dragstart", dragStartHandler)
      target.removeEventListener("dragenter", dragEnterHandler)
      target.removeEventListener("dragover", dragOverHandler)
      target.removeEventListener("dragend", dragEndHandler)
    }

    function reset_drag_handlers_for_placeholder(target) {
      target.addEventListener("dragstart", dragStartHandler)
      target.addEventListener("dragenter", dragEnterHandler)
      target.addEventListener("dragover", dragOverHandler)
      target.addEventListener("dragend", dragEndHandler)
    }

    function attach_drag_handlers(target) {
      target.addEventListener("dragstart", dragStartHandler)
      target.addEventListener("dragenter", dragEnterHandler)
      target.addEventListener("dragover", dragOverHandler)
      target.addEventListener("dragleave", dragLeaveHandler)
      target.addEventListener("drop", dropHandler)
      target.addEventListener("dragend", dragEndHandler)
    }

    // for each drop_target, add event listeners
    let draggable_task_items = document.querySelectorAll(".draggable_task_item")
    draggable_task_items.forEach((item) => {
      attach_drag_handlers(item)
    })

  }

  mount() {
    this.setup_batch_tasks()
    this.setup_drag_and_drop()
  }

  unmount() {
    console.log('TaskView unmounted')
  }
}
