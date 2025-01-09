- Attributes
  - Name
  - Type (number, text, image, file)
  - Value

- History
  - Team history
  - Project history
  - Iteration history


Velocity:
- All tasks, personal and team
- For a given task, is this a team task or a personal task?
- If this is a team task?
  - Yes: get the team's velocity.
- Not a team task?
  - Get the creator's velocity.

Calculating a user or team's velocity:
  - Average of last 3 weeks, with emphasis put on the previous week's velocity.
    So, ((last week * 2) + (prior 2 weeks)) / 4
  - If current week's velocity is already higher than the average:
    ((current-week * 2) + (last week + prior week)) / 2
  - if a week's velocity is 0, set it to the greater of: 
    - the prior week's velocity.
    - minimum velocity.

Velocity calculator:
  - Runs on startup, and once per day.
  - If not calculated for the prior cycle, calculate velocity for every user
  - Calculates velocity for every team.

  - Store calculated_velocity
  - Store velocity_date
  
