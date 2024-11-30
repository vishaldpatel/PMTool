export default TaskView = function() {
  function setup_batch_tasks() {
    selected_tasks = {}
    batch_task_options = document.getElementById("batch_task_options")

    function checkbox_clicked_handler(event) {
      task_container = document.getElementById("show-task-"+event.detail.slug)
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

  let _el = null
  let _task_slug = null
  let _above_slug = null
  let _noq = 0

  function setup_drag_and_drop() {
    function shrink_targets() {
      let targets = document.querySelectorAll(".drop_target")

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
  }

  function mount() {
    setup_batch_tasks()
    setup_drag_and_drop()
  }

  function unmount() {
    console.log('TaskView unmounted')
  }
}
