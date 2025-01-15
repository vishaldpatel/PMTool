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
      let btns_add_to_project = document.getElementsByClassName("btn_add_to_project")
      let btns_move_to_team = document.getElementsByClassName("btn_move_to_team")

      task_container.classList.toggle('bg-orange-500')

      if (document.querySelectorAll(`input[name="${stage}_task_slugs[]"]:checked`).length > 0) {
        task_options.style.display = "inline-block"
        for (let x = 0; x < btns_add_to_project.length; x++) {
          btns_add_to_project[x].style.display = "inline-block"
        }
        for (let x = 0; x < btns_move_to_team.length; x++) {
          btns_move_to_team[x].style.display = "inline-block"
        }
      } else {
        task_options.style.display = "none"
        for (let x = 0; x < btns_add_to_project.length; x++) {
          btns_add_to_project[x].style.display = "none"
        }
        for (let x = 0; x < btns_move_to_team.length; x++) {
          btns_move_to_team[x].style.display = "none"
        }
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

      let selected_tasks = []
      let is_set = false
      if (btns_add_to_project.length > 0) {
        selected_tasks = btns_add_to_project[0].getAttributeNode("phx-value-selected_tasks").value
      } else if (btns_move_to_team.length > 0) {
        selected_tasks = btns_move_to_team[0].getAttributeNode("phx-value-selected_tasks").value
      }
      selected_tasks = selected_tasks == "" ? [] : selected_tasks.split(",")

      if (event.target.checked) {
        task_options.innerHTML += `<input type="hidden" name="task_slugs[]" value="${event.detail.slug}" id="chk-${event.detail.slug}">`
        if (selected_tasks.length == 0) {
          selected_tasks.push(event.detail.slug)
        }
        else if (selected_tasks.length >= 1) {
          selected_tasks.push(event.detail.slug)
          selected_tasks = selected_tasks.join(",")
        }

        for (let x = 0; x < btns_add_to_project.length; x++) {
          btns_add_to_project[x].setAttribute("phx-value-selected_tasks", selected_tasks)
        }
        for (let x = 0; x < btns_move_to_team.length; x++) {
          btns_move_to_team[x].setAttribute("phx-value-selected_tasks", selected_tasks)
        }
      } else {
        // Remove element with id of chk-id
        document.getElementById(`chk-${event.detail.slug}`).remove()
        if (selected_tasks.length > 0) {
          const index = selected_tasks.indexOf(event.detail.slug);
          if (index > -1) {
            selected_tasks.splice(index, 1);
            selected_tasks = selected_tasks.join(",")
          }
        }

        for (let x = 0; x < btns_add_to_project.length; x++) {
          btns_add_to_project[x].setAttribute("phx-value-selected_tasks", selected_tasks)
        }
        for (let x = 0; x < btns_move_to_team.length; x++) {
          btns_move_to_team[x].setAttribute("phx-value-selected_tasks", selected_tasks)
        }
      }
    }

    if (! document.task_checkbox_clicked) {
      document.addEventListener("task_checkbox_clicked", checkbox_clicked_handler)
      document.task_checkbox_clicked = true
    }
  }

  setup_drag_and_drop() {
    let _currently_over = null
    let _move_element = null
    let _task_slug = null
    let _above_slug = null
    let _noq = 0
    let _posX = null
    let _posY = null
    let _drop_was_made = false

    function isBefore(e1li, e2li) {
      if ((e2li !== null) && (e2li.parentNode === e1li.parentNode))
        for (let cur = e1li.previousSibling; cur && cur.nodeType !== Node.DOCUMENT_NODE; cur = cur.previousSibling)
          if (cur === e2li)
            return true
      return false
    }

    function maybe_move_element_to(target) {
      if (target !== _move_element) {
        let target_li = target.closest(".task_list_item")
        let subject_li = _move_element.closest(".task_list_item")
        if (isBefore(target_li, subject_li)) {
          // og element is above target
          let next_sibling = target_li.nextSibling
          if (next_sibling) {
            target_li.parentNode.insertBefore(subject_li, next_sibling)
          } else {
            target_li.parentNode.appendChild(subject_li)
          }
          _task_slug = _move_element.querySelector(".task_slug").value
          _above_slug = target.querySelector(".task_slug").value
          _noq = "move_below"
        } else {
          // og element is below target
          target_li.parentNode.insertBefore(subject_li, target_li)
          _task_slug = _move_element.querySelector(".task_slug").value
          _above_slug = target.querySelector(".task_slug").value
          _noq = "move_above"
        }
      }
    }

    function unsetPlaceholder(target) {
      if ((target) && (target.classList.contains("opacity-50"))) {
        target.classList.remove("opacity-50")
      }
    }

    function setPlaceholder(target) {
      if (!target.classList.contains("opacity-50")) {
        target.classList.add("opacity-50")
      }
    }

    function dragEndHandler(e) {
      if (_move_element.classList.contains("opacity-50")) {
        _move_element.classList.remove("opacity-50")
      }
      _move_element = null
      _currently_over = null

      if (!_drop_was_made) {
        window.dispatchEvent(
          new CustomEvent("move_task", {
            detail: {
              action: "cancel"
            }
          })
        )
      }
      _drop_was_made = false
    }

    function dropHandler(e) {
      let project_element = e.target.closest(".droppable_project_target")
      let target_project_slug = null
      if (project_element) {
        target_project_slug = project_element.querySelector(".project_slug").value
      }
      _drop_was_made = true
      let p = e.target
      unsetPlaceholder(p)
      window.dispatchEvent(
        new CustomEvent("move_task", {
          detail: {
            active_task_slug: _task_slug, 
            affected_task_slug: _above_slug, 
            target_project_slug: target_project_slug,
            action: _noq
          }
        })
      )
    }

    function dragLeaveHandler(e) {
      let p = e.target.closest(".draggable_task_item")
      if (p) {
        unsetPlaceholder(p)
      }
    }

    function dragOverHandler(e) {
      e.preventDefault()
      let p = e.target.closest(".draggable_task_item")
      if (p) {
        _currently_over = p
        maybe_move_element_to(p)
        setPlaceholder(p)
      }
    }

    function dragStartHandler(e) {
      e.dataTransfer.effectAllowed = "move"
      e.dataTransfer.setData("text/plain", null) // Thanks to bqlou for their comment.
      _move_element = e.target.closest(".draggable_task_item")
    }

    function attach_drag_handlers(target) {
      target.ondragstart = dragStartHandler
      target.ondragleave = dragLeaveHandler
      target.ondragover = dragOverHandler
      target.ondragend = dragEndHandler
      target.ondrop = dropHandler
    }

    // for each drop_target, add event listeners
    let draggable_task_items = [...document.getElementsByClassName("draggable_task_item")]
    draggable_task_items.forEach((item) => {
      attach_drag_handlers(item)
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

  make_tag_editing_work() {
    function findParent(target, parent_class) {
      if ((target.classList) && (target.classList.contains(parent_class))) {
        return target
      } else {
        return findParent(target.parentNode, parent_class)
      }
    }

    function getTagLimtFor(target) {
      let outer_tag = findParent(target, "tags_outer")
      let tag_limit = outer_tag.querySelector('input[name="tag_limit"]').value
      return tag_limit
    }

    function getTagTypeFor(target) {
      let outer_tag = findParent(target, "tags_outer")
      let tag_type = outer_tag.querySelector('input[name="tag_type"]').value
      return tag_type
    }

    function maybe_toggle_tag_adding(target) {
      let tag_limit = getTagLimtFor(target)
      let outer_tag = findParent(target, "tags_outer")

      if ((tag_limit == 0) || (target.querySelectorAll(".tag").length < tag_limit)) {
        outer_tag.querySelector(`.new_tag_input`).disabled = false
      } else if (target.querySelectorAll(".tag").length >= tag_limit) {
        outer_tag.querySelector(`.new_tag_input`).disabled = true
      }
    }

    function remove_tag(e) {
      e.preventDefault()
      let tag = findParent(e.target, "tag")
      let tag_parent = tag.parentNode
      tag_parent.removeChild(tag)
      maybe_toggle_tag_adding(tag_parent)
    }

    let remove_tag_buttons = document.getElementsByClassName("remove_tag")
    for (let x = 0; x < remove_tag_buttons.length; x++) {
      let remove_tag_button = remove_tag_buttons[x]
      remove_tag_button.onclick = remove_tag
    }

    let tag_editors = document.getElementsByClassName("new_tag_input")
    for (let x = 0; x < tag_editors.length; x++) {
      let tag_editor = tag_editors[x]
      tag_editor.addEventListener("keydown", function(e) {
        if ((e.keyCode == 188) || (e.keyCode == 59) || (e.keyCode == 186) || (e.keyCode == 13)) {
          e.preventDefault()
          let new_tag_name = tag_editor.value
          let tags = e.target.parentNode.querySelector(".tags")
          if (new_tag_name != "") {
            let space = document.createTextNode(" ")
            tags.appendChild(space)

            let new_tag_div = document.createElement("div")
            new_tag_div.setAttribute("class", "tag inline")

            let new_tag_hidden_input = document.createElement("input")
            new_tag_hidden_input.setAttribute("type", "hidden")

            let tag_limit = getTagLimtFor(e.target)
            let tag_type = getTagTypeFor(e.target)
            if (tag_limit == 1) {
              new_tag_hidden_input.setAttribute("name", `${tag_type}[tag]`)
            } else {
              new_tag_hidden_input.setAttribute("name", `${tag_type}[tags][]`)
            }

            new_tag_hidden_input.setAttribute("value", new_tag_name)
            new_tag_div.appendChild(new_tag_hidden_input)

            let new_tag_button = document.createElement("button")
            new_tag_button.onclick = remove_tag
            new_tag_button.setAttribute("class", "remove_tag px-1 mb-1 text-xs font-xs text-cyan-200 bg-cyan-800 hover:bg-zinc-700")
            new_tag_button.innerHTML = `<span>&#10005; &#10072;</span> <span class="italic">${new_tag_name}</span>`
            new_tag_div.appendChild(new_tag_button)

            tags.appendChild(new_tag_div)
            maybe_toggle_tag_adding(e.target.parentNode)
          }
          tag_editor.value = ""
        }
      })
    }

    let tags_outers = document.getElementsByClassName("tags_outer")
    for (let x = 0; x < tags_outers.length; x++) {
      let tags_outer = tags_outers[x]
      tags_outer.onclick = function(e) {
        e.stopPropagation()
        tags_outer.querySelector(".new_tag_input").focus()
      }
    }
  }

  mount() {
    this.setup_batch_tasks()
    this.setup_drag_and_drop()
    this.setup_estimate_hovering()
    this.make_tag_editing_work()
  }
}
