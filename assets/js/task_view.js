export default class TaskView {
  setup_batch_tasks() {
    let selected_tasks = {}
    let batch_task_options = document.getElementById("batch_task_options")

    function checkbox_clicked_handler(event) {
      let task_container = document.getElementById("show-"+event.detail.id)
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

    if (! document.task_checkbox_clicked) {
      document.addEventListener("task_checkbox_clicked", checkbox_clicked_handler)
      document.task_checkbox_clicked = true
    }
  }

  setup_drag_and_drop() {
    var _move_element = null
    var _task_slug = null
    var _above_slug = null
    var _noq = 0

    function move_element_to(target) {
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
      target.classList.remove("bg-orange-500")
      target.classList.add("bg-gray-600")
    }

    function setPlaceholder(target) {
      target.classList.remove("bg-gray-600")
      target.classList.add("bg-orange-500")
    }

    function dragEndHandler(e) {
      e.preventDefault()
      unset_placeholder(_move_element)
      _move_element = null
    }

    function dropHandler(e) {
      e.preventDefault()
      unset_placeholder(e.target)
      let move_task_event = new CustomEvent("move_task", {detail: {active_task_slug: _task_slug, affected_task_slug: _above_slug, action: _noq}})
      window.dispatchEvent(move_task_event)
    }

    function dragLeaveHandler(e) {
      e.preventDefault()
      if (e.target.getAttribute("draggable") == "true") {
        unset_placeholder(e.target)
      }
    }

    function dragEnterHandler(e) {
      e.preventDefault()
    }

    function dragOverHandler(e) {
      e.preventDefault()
      if (e.target.getAttribute("draggable") == "true") {
        setPlaceholder(e.target)
        move_element_to(e.target)
      }
    }

    function dragStartHandler(e) {
      e.dataTransfer.effectAllowed = "move"
      e.dataTransfer.setData("text/plain", null) // Thanks to bqlou for their comment.
      _move_element = e.target
      setPlaceholder(e.target)
    }

    function isBefore(el1, el2) {
      if ((el2 !== null) && (el2.parentNode === el1.parentNode))
        for (var cur = el1.previousSibling; cur && cur.nodeType !== Node.DOCUMENT_NODE; cur = cur.previousSibling)
          if (cur === el2)
            return true
      return false
    }

    function attach_drag_handlers(target) {
      target.ondragstart = dragStartHandler
      target.ondragenter = dragEnterHandler
      target.ondragover = dragOverHandler
      target.ondragleave = dragLeaveHandler
      target.ondragend = dragEndHandler
      target.ondrop = dropHandler
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
}
