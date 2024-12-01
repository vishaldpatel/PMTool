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
    var _el = null
    var _task_slug = null
    var _above_slug = null
    var _noq = 0

    function shrink_targets() {
      let targets = document.querySelectorAll(".draggable_task_item")

      targets.forEach((target) => {
        target.classList.remove("py-1")
      })
    }

    function dragEndHandler() {
      event.preventDefault()
    }

    function dropHandler(e) {
      event.preventDefault()
      shrink_targets()
      console.log(_task_slug, _above_slug, _noq)
    }

    function move_target(target) {
      if (target.parentNode.getAttribute("draggable") == "true") {
        let li_node = target.parentNode
        if (li_node !== _el) {
          if (isBefore(_el, li_node)) {
            li_node.parentNode.insertBefore(_el, li_node)
            _task_slug = _el.querySelector(".task_slug").value
            _above_slug = li_node.querySelector(".task_slug").value
            _noq = "move_above"
          } else {
            li_node.parentNode.insertBefore(_el, li_node.nextElementSibling)
            _task_slug = _el.querySelector(".task_slug").value
            _above_slug = li_node.querySelector(".task_slug").value
            _noq = "move_below"
          }
        }
      }
    }

    function dragLeaveHandler(e) {
      e.preventDefault()
    }

    function dragEnterHandler(e) {
      move_target(e.target)
    }

    function dragOverHandler(e) {
      move_target(e.target)
    }

    function dragStartHandler(e) {
      e.dataTransfer.effectAllowed = "move"
      e.dataTransfer.setData("text/plain", null) // Thanks to bqlou for their comment.
      _el = e.target
    }

    function isBefore(el1, el2) {
      if (el2.parentNode === el1.parentNode)
        for (var cur = el1.previousSibling; cur && cur.nodeType !== Node.DOCUMENT_NODE; cur = cur.previousSibling)
          if (cur === el2)
            return true
      return false
    }

    // for each drop_target, add event listeners
    let draggable_task_items = document.querySelectorAll(".draggable_task_item")
    draggable_task_items.forEach((item) => {
      item.addEventListener("dragstart", dragStartHandler)
      item.addEventListener("dragenter", dragEnterHandler)
      item.addEventListener("dragover", dragOverHandler)
      item.addEventListener("dragleave", dragLeaveHandler)
      item.addEventListener("drop", dropHandler)
      item.addEventListener("dragend", dragEndHandler)
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
