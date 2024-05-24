-- Initializing global variables to store the latest game state and game host process.
LatestGameState = LatestGameState or nil
InAction = InAction or false -- Prevents the agent from taking multiple actions at once.

Logs = Logs or {}

colors = {
  red = "\27[31m",
  green = "\27[32m",
  blue = "\27[34m",
  reset = "\27[0m",
  gray = "\27[90m"
}

function addLog(msg, text) -- Function definition commented for performance, can be used for debugging
  Logs[msg] = Logs[msg] or {}
  table.insert(Logs[msg], text)
end

-- Checks if two points are within a given range.
-- @param x1, y1: Coordinates of the first point.
-- @param x2, y2: Coordinates of the second point.
-- @param range: The maximum allowed distance between the points.
-- @return: Boolean indicating if the points are within the specified range.
function inRange(x1, y1, x2, y2, range)
    return math.abs(x1 - x2) <= range and math.abs(y1 - y2) <= range
end

-- Decides the next action based on player proximity and energy.
-- If any player is within range, it initiates an attack; otherwise, moves randomly.
function decideNextAction()
  local mychar = LatestGameState.Players[ao.id]
  local targetInRange = false

  for target, state in pairs(LatestGameState.Players) do
      if target ~= ao.id and inRange(mychar.x, mychar.y, state.x, state.y, 1) then
          targetInRange = true
          break
      end
  end

  -- Table for randomize direction
  local randomDirectionMap = {"Up", "Down", "Left", "Right", "UpRight", "UpLeft", "DownRight", "DownLeft"}
  local randomIndex = math.random(#randomDirectionMap)
  local randomDirection = randomDirectionMap[randomIndex]
  -- Table for avoid fail direction
  -- avoid up
  local avoidUp = {x = 0}
  local directionAvoidUp = {"Down", "Left", "Right", "DownRight", "DownLeft"}
  local randomIndexAvoidUp = math.random(#directionAvoidUp)
  local randomAvoidUpDirection = directionAvoidUp[randomIndexAvoidUp]
  --avoid down
  local avoidDown = {x = 39}
  local directionAvoidDown = {"Up", "Right", "Left", "UpLeft", "UpRight"}
  local randomIndexAvoidDown = math.random(#directionAvoidDown)
  local randomAvoidDownDirection = directionAvoidDown[randomIndexAvoidDown]
  -- avoid left
  local avoidLeft = {y = 0}
  local directionAvoidLeft = {"Down", "Up", "Right", "DownRight", "UpRight"}
  local randomIndexAvoidLeft = math.random(#directionAvoidLeft)
  local randomAvoidLeftDirection = directionAvoidLeft[randomIndexAvoidLeft]
  -- avoid right
  local avoidRight = {y = 39}
  local directionAvoidRight = {"Down", "Up", "Left", "DownLeft", "Upleft"}
  local randomIndexAvoidRight = math.random(#directionAvoidRight)
  local randomAvoidRightDirection = directionAvoidRight[randomIndexAvoidRight]

    -- Logic for bot
    if mychar.health < 10 then
        print(colors.red .. "Run from the battle or we lose, retreat to " .. randomDirection .. "(" .. mychar.x .. ", ".. mychar.y .. ")" .. colors.reset)
        ao.send({ Target = Game, Action = "PlayerMove", Player = ao.id, Direction = randomDirectionMap[randomIndex] })
    elseif
        mychar.energy > 10 and targetInRange then
        print(colors.red .. "Attacking our enemy!" .. colors.reset)
        ao.send({ Target = Game, Action = "PlayerAttack", Player = ao.id, AttackEnergy = tostring(player.energy) })
    elseif
        mychar.x == avoidUp then
        print(colors.red .. "We find the good direction, and avoid up to the center battle. " .. randomAvoidUpDirection .. "(" .. mychar.x .. ", ".. mychar.y .. ")" .. colors.reset)
        ao.send({ Target = Game, Action = "PlayerMove", Player = ao.id, Direction = directionAvoidUp[randomIndexAvoidUp] })
    elseif
        mychar.x == avoidDown then
        print(colors.red .. "We find the good direction, and avoid down to the center battle. " .. randomAvoidDownDirection .. "(" .. mychar.x .. ", ".. mychar.y .. ")" .. colors.reset)
        ao.send({ Target = Game, Action = "PlayerMove", Player = ao.id, Direction = directionAvoidDown[randomIndexAvoidDown] })
    elseif
        mychar.y == avoidLeft then
        print(colors.red .. "We find the good direction, and avoid left to the center battle. " .. randomAvoidLeftDirection .. "(" .. mychar.x .. ", ".. mychar.y .. ")" .. colors.reset)
        ao.send({ Target = Game, Action = "PlayerMove", Player = ao.id, Direction = directionAvoidLeft[randomIndexAvoidLeft] })
    elseif
        mychar.y == avoidRight then
        print(colors.red .. "We find the good direction, and avoid right to the center battle. " .. randomAvoidRightDirection .. "(" .. mychar.x .. ", ".. mychar.y .. ")" .. colors.reset)
        ao.send({ Target = Game, Action = "PlayerMove", Player = ao.id, Direction = directionAvoidRight[randomIndexAvoidRight] })
    else
        print(colors.red .. "I dont know where am i, and where are our enemy move to " .. randomDirection .. "(" .. mychar.x .. ", ".. mychar.y .. ")".. colors.reset)
        ao.send({ Target = Game, Action = "PlayerMove", Player = ao.id, Direction = randomDirectionMap[randomIndex] })
    end
    InAction = false -- InAction logic added
end

-- Handler to print game announcements and trigger game state updates.
Handlers.add(
  "PrintAnnouncements",
  Handlers.utils.hasMatchingTag("Action", "Announcement"),
  function (msg)
    if msg.Event == "Started-Waiting-Period" then
      ao.send({Target = ao.id, Action = "AutoPay"})
    elseif (msg.Event == "Tick" or msg.Event == "Started-Game") and not InAction then
      InAction = true -- InAction logic added
      ao.send({Target = Game, Action = "GetGameState"})
    elseif InAction then -- InAction logic added
      print("Previous action still in progress. Skipping.")
    end
    print(colors.green .. msg.Event .. ": " .. msg.Data .. colors.reset)
  end
)

-- Handler to trigger game state updates.
Handlers.add(
  "GetGameStateOnTick",
  Handlers.utils.hasMatchingTag("Action", "Tick"),
  function ()
    if not InAction then -- InAction logic added
      InAction = true -- InAction logic added
      print(colors.gray .. "Getting game state..." .. colors.reset)
      ao.send({Target = Game, Action = "GetGameState"})
    else
      print("Previous action still in progress. Skipping.")
    end
  end
)

-- Handler to automate payment confirmation when waiting period starts.
Handlers.add(
  "AutoPay",
  Handlers.utils.hasMatchingTag("Action", "AutoPay"),
  function (msg)
    print("Auto-paying confirmation fees and get the game state.")
    ao.send({ Target = Game, Action = "Transfer", Recipient = Game, Quantity = "1000"})
    ao.send({Target = Game, Action = "GetGameState"})
  end
)

-- Handler to update the game state upon receiving game state information.
Handlers.add(
  "UpdateGameState",
  Handlers.utils.hasMatchingTag("Action", "GameState"),
  function (msg)
    local json = require("json")
    LatestGameState = json.decode(msg.Data)
    ao.send({Target = ao.id, Action = "UpdatedGameState"})
    print("Game state updated. Print \'LatestGameState\' for detailed view.")
  end
)

-- Handler to decide the next best action.
Handlers.add(
  "decideNextAction",
  Handlers.utils.hasMatchingTag("Action", "UpdatedGameState"),
  function ()
    if LatestGameState.GameMode ~= "Playing" then
      InAction = false -- InAction logic added
      return
    end
    print("Deciding next action.")
    decideNextAction()
    ao.send({Target = ao.id, Action = "Tick"})
  end
)

-- Handler to automatically attack when hit by another player.
Handlers.add(
  "ReturnAttack",
  Handlers.utils.hasMatchingTag("Action", "Hit"),
  function (msg)
    if not InAction then -- InAction logic added
      InAction = true -- InAction logic added
      local playerEnergy = LatestGameState.Players[ao.id].energy
      if playerEnergy == undefined then
        print(colors.red .. "Unable to read energy." .. colors.reset)
        ao.send({Target = Game, Action = "Attack-Failed", Reason = "Unable to read energy."})
      elseif playerEnergy == 0 then
        print(colors.red .. "Player has insufficient energy." .. colors.reset)
        ao.send({Target = Game, Action = "Attack-Failed", Reason = "Player has no energy."})
      else
        print(colors.red .. "Returning attack." .. colors.reset)
        ao.send({Target = Game, Action = "PlayerAttack", Player = ao.id, AttackEnergy = tostring(playerEnergy)})
      end
      InAction = false -- InAction logic added
      ao.send({Target = ao.id, Action = "Tick"})
    else
      print("Previous action still in progress. Skipping.")
    end
  end
)

-- Handler to register when get ejected from Game
Handlers.add(
    "RegisterAfterEjedted",
    Handlers.utils.hasMatchingTag("Action", "Ejected"),
    function (msg)
        print(colors.gray .. "Get Rejected by Game, Registering and AutoPay and fetch the game state..." .. colors.reset)
        ao.send({Target = Game, Action = "Register"})
        ao.send({Target = ao.id, Action = "AutoPay"})
        ao.send({Target = Game, Action = "GetGameState"})
    end
)