export default class TaskView {
  setup_batch_tasks() {
    let now_task_options = document.getElementById("now_task_options")
    let next_task_options = document.getElementById("next_task_options")
    let done_task_options = document.getElementById("done_task_options")
    let later_task_options = document.getElementById("later_task_options")

    function task_options_for_stage(stage) {
      if (stage === "Now") {
        return now_task_options
      } else if (stage === "Next") {
        return next_task_options
      } else if (stage === "Done") {
        return done_task_options
      } else if (stage === "Later") {
        return later_task_options
      }
    }

    function checkbox_clicked_handler(event) {
      let stage = event.detail.stage
      let task_options = task_options_for_stage(stage)
      let task_container = document.getElementById("show-"+event.detail.id)
      task_container.classList.toggle('bg-orange-500')

      if (document.querySelectorAll(`input[name="${stage}_task_slugs[]"]:checked`).length > 0) {
        task_options.style.display = "inline-block"
      } else {
        task_options.style.display = "none"
      }

      if (event.detail.project_slug) {
        let project_panel = document.getElementById("project-tasks-"+event.detail.project_slug)
        let project_task_options = document.getElementById("project_task_options_"+event.detail.project_slug)
        if (project_panel.querySelectorAll(`input[type="checkbox"]:checked`).length > 0) {
          project_task_options.style.display = "inline-block"
        } else {
          project_task_options.style.display = "none"
        }

        if (event.target.checked) {
          project_task_options.innerHTML += `<input type="hidden" name="task_slugs[]" value="${event.detail.slug}" id="chk-${event.detail.slug}">`
        } else {
          // Remove element with id of chk-id
          document.getElementById(`chk-${event.detail.slug}`).remove()
        }
      }

      if (event.target.checked) {
        task_options.innerHTML += `<input type="hidden" name="task_slugs[]" value="${event.detail.slug}" id="chk-${event.detail.slug}">`
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
    let _move_element = null
    let _task_slug = null
    let _above_slug = null
    let _noq = 0

    function move_element_to(target) {
      if (target !== _move_element) {
        if (isBefore(_move_element.parentNode, target.parentNode)) {
          target.parentNode.parentNode.insertBefore(_move_element.parentNode, target.parentNode)
          _task_slug = _move_element.querySelector(".task_slug").value
          _above_slug = target.querySelector(".task_slug").value
          _noq = "move_above"
        } else {
          target.parentNode.parentNode.insertBefore(_move_element.parentNode, target.parentNode.nextSibling)
          _task_slug = _move_element.querySelector(".task_slug").value
          _above_slug = target.querySelector(".task_slug").value
          _noq = "move_below"
        }
      }
    }

    function unsetPlaceholder(target) {
      target.classList.remove("bg-orange-500")
      target.classList.add("bg-gray-600")
      target.classList.add("hover:bg-gray-500")
    }

    function setPlaceholder(target) {
      target.classList.remove("bg-gray-600")
      target.classList.remove("hover:bg-gray-500")
      target.classList.add("bg-orange-500")
    }

    function dragEndHandler(e) {
      e.preventDefault()
      unsetPlaceholder(_move_element)
      _move_element = null
    }

    function dropHandler(e) {
      e.preventDefault()
      let project_element = e.target.closest(".droppable_project_target")
      if (project_element) {
        let _target_project_slug = project_element.querySelector(".project_slug").value
        project_element.classList.remove("bg-orange-200")
        _task_slug = _move_element.querySelector(".task_slug").value
        window.dispatchEvent(
          new CustomEvent("move_task", {
            detail: {
              task_slug: _task_slug, 
              target_project_slug: _target_project_slug 
            }
          })
        )
      } else {
        let p = e.target.parentNode.parentNode
        unsetPlaceholder(p)
        window.dispatchEvent(
          new CustomEvent("move_task", {
            detail: {
              active_task_slug: _task_slug, 
              affected_task_slug: _above_slug, 
              action: _noq
            }
          })
        )
      }
    }

    function dragLeaveHandler(e) {
      e.preventDefault()
      let project_element = e.target.closest(".droppable_project_target")
      if (project_element) {
        project_element.classList.remove("bg-orange-200")
      } else {
        let p = e.target.parentNode.parentNode
        if (p.getAttribute("draggable") == "true") {
          unsetPlaceholder(p)
        }
        else if (e.target.getAttribute("draggable") == "true") {
          unsetPlaceholder(e.target)
        }
      }
    }

    function dragEnterHandler(e) {
      e.preventDefault()
      let project_element = e.target.closest(".droppable_project_target")
      if (project_element) {
        project_element.classList.add("bg-orange-200")
      } else {
        let p = e.target.parentNode.parentNode
        if (p.getAttribute("draggable") == "true") {
          setPlaceholder(p)
          move_element_to(p)
        }
        else if (e.target.getAttribute("draggable") == "true") {
          setPlaceholder(e.target)
          move_element_to(e.target)
        }
      }
    }

    function dragOverHandler(e) {
      e.preventDefault()
      let project_element = e.target.closest(".droppable_project_target")
      if (project_element) {
        project_element.classList.add("bg-orange-200")
      } else {
        let p = e.target.parentNode.parentNode
        if (p.getAttribute("draggable") == "true") {
          setPlaceholder(p)
          move_element_to(p)
        }
        else if (e.target.getAttribute("draggable") == "true") {
          setPlaceholder(e.target)
          move_element_to(e.target)
        }
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

    function attach_drop_handlers(target) {
      target.ondrop = dropHandler
      target.ondragover = dragOverHandler
      target.ondragenter = dragEnterHandler
      target.ondragleave = dragLeaveHandler
    }

    // for each drop_target, add event listeners
    let draggable_task_items = document.querySelectorAll(".draggable_task_item")
    draggable_task_items.forEach((item) => {
      attach_drag_handlers(item)
    })

    let droppable_project_targets = document.querySelectorAll(".droppable_project_target")
    droppable_project_targets.forEach((item) => {
      attach_drop_handlers(item)
    })
  }

  setup_estimate_hovering() {
    let estimates = [1, 2, 4, 6, 8, 12]

    function hide_estimate(e) {
      if (e.target.classList.contains("estimation_station")) {
        let estimate_number = e.target.parentNode.querySelector(".estimate_number")
        estimate_number.innerText = ""
      }
    }

    function show_estimate(e) {
      if (e.target.classList.contains("estimator")) {
        e.preventDefault()
        let relevant_parent = e.target.parentNode.parentNode
        let estimate_number = relevant_parent.querySelector(".estimate_number")
        for (let x = 0; x < estimates.length; x++) {
          let i = estimates[x]
          if (e.target.getAttribute("value") == i) {
            estimate_number.innerText = i
          }
        }
      }
    }

    let estimation_stations = document.getElementsByClassName("estimation_station")
    for (let x = 0; x < estimation_stations.length; x++) {
      estimation_stations[x].onmouseleave = hide_estimate
    }
    let estimators = document.getElementsByClassName("estimator")
    for (let x = 0; x < estimators.length; x++) {
      estimators[x].onmouseover = show_estimate
    }
  }

  make_label_editing_work() {
    function remove_label(e) {
      e.preventDefault()
      let label = e.target
      let label_parent = e.target.parentNode
      while (! label.classList.contains("label")) {
        label = label.parentNode
        label_parent = label_parent.parentNode
      }
      label_parent.removeChild(label)
    }

    let remove_label_buttons = document.getElementsByClassName("remove_label")
    for (let x = 0; x < remove_label_buttons.length; x++) {
      let remove_label_button = remove_label_buttons[x]
      remove_label_button.onclick = remove_label
    }

    let label_editors = document.getElementsByClassName("new_label_input")
    for (let x = 0; x < label_editors.length; x++) {
      let label_editor = label_editors[x]
      label_editor.addEventListener("keydown", function(e) {
        if ((e.keyCode == 188) || (e.keyCode == 59) || (e.keyCode == 186) || (e.keyCode == 13)) {
          e.preventDefault()
          let new_label_name = label_editor.value
          let labels = e.target.parentNode.querySelector(".labels")
          if (new_label_name != "") {
            let space = document.createTextNode(" ")
            labels.appendChild(space)

            let new_label_div = document.createElement("div")
            new_label_div.setAttribute("class", "label inline")

            let new_label_hidden_input = document.createElement("input")
            new_label_hidden_input.setAttribute("type", "hidden")
            new_label_hidden_input.setAttribute("name", "task[labels][]")
            new_label_hidden_input.setAttribute("value", new_label_name)
            new_label_div.appendChild(new_label_hidden_input)

            let new_label_button = document.createElement("button")
            new_label_button.onclick = remove_label
            new_label_button.setAttribute("class", "remove_label px-1 mb-1 text-xs font-xs text-cyan-200 bg-cyan-800 hover:bg-zinc-700")
            new_label_button.innerHTML = `<span>&#10005; &#10072;</span> <span class="italic">${new_label_name}</span>`
            new_label_div.appendChild(new_label_button)

            labels.appendChild(new_label_div)
          }
          label_editor.value = ""
        }
      })
    }
  }

  mount() {
    this.setup_batch_tasks()
    this.setup_drag_and_drop()
    this.setup_estimate_hovering()
    this.make_label_editing_work()
  }
}
