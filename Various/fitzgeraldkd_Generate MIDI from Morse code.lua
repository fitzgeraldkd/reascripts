--[[
  ReaScript Name: Generate MIDI from Morse code
  Author: fitzgeraldkd
  Version: 1.00
  Link: https://github.com/fitzgeraldkd/reascripts
  About:
    This script is based on the International Morse Code Recommendation ITU-R M.1677-1 
    (10/2009). A trailing space (equivalent to the time of seven dots) is included at 
    the end of the MIDI item to allow for clean looping.
  Changelog:
    # v1.00 (2023-08-23)
    - Initial release
]]


-------------------------
-- USER CONFIG ----------
-------------------------

tick_duration = 0.25 -- Where 1 is a quarter note.
dit_midi_note = 80
dah_midi_note = 80
note_velocity = 64


-----------------------
-- CONSTANTS ----------
-----------------------

CHARACTER_TABLE = {
  a=".-",
  b="-...",
  c="-.-.",
  d="-..",
  e=".",
  f="..-.",
  g="--.",
  h="....",
  i="..",
  j=".---",
  k="-.-",
  l=".-..",
  m="--",
  n="-.",
  o="---",
  p=".--.",
  q="--.-",
  r=".-.",
  s="...",
  t="-",
  u="..-",
  v="...-",
  w=".--",
  x="-..-",
  y="-.--",
  z="--..",
  ["0"]="-----",
  ["1"]=".----",
  ["2"]="..---",
  ["3"]="...--",
  ["4"]="....-",
  ["5"]=".....",
  ["6"]="-....",
  ["7"]="--...",
  ["8"]="---..",
  ["9"]="----.",
  ["."]=".-.-.-",
  [","]="--..--",
  ["?"]="..--..",
  ["'"]=".----.",
  ["/"]="-..-.",
  ["("]="-.--.",
  [")"]="-.--.-",
  [":"]="---...",
  ["="]="-...-",
  ["+"]=".-.-.",
  ["-"]="-....-",
  ['"']=".-..-.",
  ["@"]=".--.-.",
}


-------------------
-- UTILS ----------
-------------------

-- Count the number of items in a table.
function get_table_length(tbl)
  local count = 0
  for n in pairs(tbl) do 
    count = count + 1 
  end
  return count
end


-- Count the number of ticks for the full message.
function count_ticks(morse)
  local ticks = get_table_length(morse) * 7
  for _, word in ipairs(morse) do
    ticks = ticks + ((get_table_length(word) - 1) * 3)
    for _, char in ipairs(word) do
      ticks = ticks + string.len(char) - 1
      for i = 1, string.len(char) do
        if string.sub(char, i, i) == '.' then
          ticks = ticks + 1
        else
          ticks = ticks + 3
        end
      end
    end
  end
  return ticks
end


-- Return a nested table representing the text as Morse code.
function text_to_morse(text)
  local morse = {}
  local word = {}
  for i = 1, string.len(text) do
    local char = string.sub(text, i, i)
    if char ~= ' ' then
      table.insert(word, CHARACTER_TABLE[char])
    elseif get_table_length(word) > 0 then
      table.insert(morse, word)
      word = {}
    end
  end
  if get_table_length(word) > 0 then
    table.insert(morse, word)
  end
  return morse
end


-- Check if all characters of the string are defined in CHARACTER_TABLE.
function validate_string(text)
  for i = 1, string.len(text) do
    local character = string.sub(text, i, i)
    if CHARACTER_TABLE[character] == nil and character ~= ' ' then
      return false
    end
  end
  return true
end


-------------------------
-- MAIN SCRIPT ----------
-------------------------

local submitted, text = reaper.GetUserInputs('Morse To MIDI', 1, 'Text', '')

if submitted and string.len(text) > 0 then
  text = string.lower(text)
  if not validate_string(text) then
    -- TODO: Indicate which character is invalid.
    reaper.ShowConsoleMsg('Invalid character provided.')
    return
  end

  local morse = text_to_morse(text)
  local ticks = count_ticks(morse)
  local tick_duration = 0.0625 * 4
  local duration = ticks * tick_duration
  local project = reaper.EnumProjects(-1)
  local track = reaper.GetSelectedTrack(project, 0)
  local cursor = reaper.GetCursorPosition()
  local current_time = reaper.TimeMap_timeToQN(cursor)
  
  reaper.Undo_BeginBlock2(project)
  local media_item = reaper.CreateNewMIDIItemInProj(track, current_time, current_time + duration, true)
  reaper.MarkProjectDirty(project)
  reaper.Undo_OnStateChange_Item(project, 'Morse To Midi script', media_item)
  local take = reaper.GetMediaItemTake(media_item, 0)
  
  for _, word in ipairs(morse) do
    for _, char in ipairs(word) do
      for i = 1, string.len(char) do
        local length = tick_duration
        local mark = string.sub(char, i, i)
        local midi_note = dit_midi_note
        if mark == '-' then
          length = length * 3
          midi_note = dah_midi_note
        end
        local note_start = reaper.MIDI_GetPPQPosFromProjQN(take, current_time)
        local note_end = reaper.MIDI_GetPPQPosFromProjQN(take, current_time + length)
        reaper.MIDI_InsertNote(take, false, false, note_start, note_end, 0, midi_note, note_velocity)
        current_time = current_time + length + tick_duration
      end
      current_time = current_time + 2 * tick_duration
    end
    current_time = current_time + 4 * tick_duration
  end
  reaper.Undo_EndBlock2(project, 'Morse To Midi script', 4)
end
