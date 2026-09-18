import os
import strutils
import times

proc findUserdata(): string =
  let home = os.getHomeDir()
  var onedrive = ""
  if os.existsEnv("OneDrive"):
    onedrive = os.getEnv("OneDrive")
  else:
    onedrive = home / "OneDrive"

  # Lista com todas as variações conhecidas do OneDrive e Desktop aninhado
  let possiblePaths = [
    onedrive / "Desktop" / "Documents" / "Egosoft" / "X4",
    onedrive / "Documents" / "Egosoft" / "X4",
    home / "Desktop" / "Documents" / "Egosoft" / "X4",
    home / "Documents" / "Egosoft" / "X4"
  ]

  var foundBasePath = ""
  for p in possiblePaths:
    if os.dirExists(p):
      foundBasePath = p
      break

  if foundBasePath == "":
    echo "ERROR: X4 folder not found in standard or OneDrive paths."
    echo "Make sure the game is installed and has been run at least once."
    return ""

  for kind, path in os.walkDir(foundBasePath):
    if kind == pcDir:
      let userdata = path / "userdata.xml"
      if os.fileExists(userdata):
        return userdata

  echo "ERROR: userdata.xml not found in X4 subfolders"
  return ""

proc makeBackup(filePath: string): bool =
  let timestamp = $now().toTime().toUnix()
  let backup = filePath & ".backup_" & timestamp

  try:
    os.copyFile(filePath, backup)
    echo "Backup created at: ", backup
    return true
  except:
    echo "ERROR creating backup"
    return false

proc getIndentation(line: string): string =
  var indentation = ""
  for c in line:
    if c == ' ' or c == '\t':
      indentation.add(c)
    else:
      break
  return indentation

proc extractTagName(line: string): string =
  var tagName = ""
  var i = 0
  while i < line.len:
    if line[i] == '<':
      var j = i + 1
      tagName = ""
      while j < line.len and line[j] != '>':
        tagName.add(line[j])
        j.inc
      if j < line.len and line[j] == '>':
        return tagName
    i.inc
  return ""

proc updateTags(content: string, newTags: seq[(string, string)]): string =
  let lines = content.splitLines()
  var existingTags: seq[string] = @[]

  # Find existing tags
  for line in lines:
    let tagName = extractTagName(line)
    if tagName.len > 0:
      existingTags.add(tagName)

  # Update existing tags
  var newLines: seq[string] = @[]
  for line in lines:
    let tagName = extractTagName(line)
    var found = false

    if tagName.len > 0:
      for tag in newTags:
        if tag[0] == tagName:
          let indentation = getIndentation(line)
          newLines.add(indentation & tag[1])
          found = true
          break

    if not found:
      newLines.add(line)

  # Add new tags
  var tagsToAdd: seq[(string, string)] = @[]
  for tag in newTags:
    var exists = false
    for existing in existingTags:
      if existing == tag[0]:
        exists = true
        break
    if not exists:
      tagsToAdd.add(tag)

  if tagsToAdd.len > 0:
    var rootClosing = -1
    var lastIndentation = "  "

    for i, line in newLines.pairs:
      if "</root>" in line:
        rootClosing = i
        break

      let tagName = extractTagName(line)
      if tagName.len > 0:
        lastIndentation = getIndentation(line)

    var newTagLines: seq[string] = @[]
    for tag in tagsToAdd:
      newTagLines.add(lastIndentation & tag[1])

    if rootClosing >= 0:
      var result: seq[string] = @[]
      for i, line in newLines.pairs:
        if i == rootClosing:
          for newTag in newTagLines:
            result.add(newTag)
        result.add(line)
      newLines = result
    else:
      for newTag in newTagLines:
        newLines.add(newTag)

  return newLines.join("\n")

proc main() =
  echo "=".repeat(60)
  echo "X4 Timelines Unlocker"
  echo "=".repeat(60)

  let filePath = findUserdata()
  if filePath == "":
    echo "\nPress Enter to exit..."
    discard readLine(stdin)
    return

  echo "\nFile found: ", filePath

  if not makeBackup(filePath):
    echo "\nPress Enter to exit..."
    discard readLine(stdin)
    return

  var content = ""
  try:
    content = readFile(filePath)
  except:
    echo "ERROR reading file"
    echo "\nPress Enter to exit..."
    discard readLine(stdin)
    return

  var newTags: seq[(string, string)] = @[]
  newTags.add(("firsttimestartmenu", "<firsttimestartmenu>false</firsttimestartmenu>"))
  newTags.add(("timelines_rankings_reset_version", "<timelines_rankings_reset_version>700</timelines_rankings_reset_version>"))
  newTags.add(("timelines_rankings_reset_revision", "<timelines_rankings_reset_revision>533594</timelines_rankings_reset_revision>"))
  newTags.add(("timelines_player_character_macro", "<timelines_player_character_macro>character_player_timelines_hub_argon_male_macro</timelines_player_character_macro>"))
  newTags.add(("timelines_hub_player_isfemale", "<timelines_hub_player_isfemale>0</timelines_hub_player_isfemale>"))
  newTags.add(("timelines_scenarios_finished", "<timelines_scenarios_finished>76</timelines_scenarios_finished>"))
  newTags.add(("scenario_chapter_1_rating", "<scenario_chapter_1_rating>20</scenario_chapter_1_rating>"))
  newTags.add(("scenario_chapter_2_rating", "<scenario_chapter_2_rating>25</scenario_chapter_2_rating>"))
  newTags.add(("scenario_chapter_3_rating", "<scenario_chapter_3_rating>30</scenario_chapter_3_rating>"))
  newTags.add(("scenario_chapter_4_rating", "<scenario_chapter_4_rating>30</scenario_chapter_4_rating>"))
  newTags.add(("scenario_chapter_5_rating", "<scenario_chapter_5_rating>25</scenario_chapter_5_rating>"))
  newTags.add(("scenario_chapter_6_rating", "<scenario_chapter_6_rating>30</scenario_chapter_6_rating>"))
  newTags.add(("timelines_hub_currenthack", "<timelines_hub_currenthack>5</timelines_hub_currenthack>"))
  newTags.add(("hub_a1s2_complete", "<hub_a1s2_complete>0</hub_a1s2_complete>"))
  newTags.add(("hub_a1s5_complete", "<hub_a1s5_complete>0</hub_a1s5_complete>"))
  newTags.add(("hub_a1s3_complete", "<hub_a1s3_complete>0</hub_a1s3_complete>"))
  newTags.add(("hub_playerinventory_interfaceunit", "<hub_playerinventory_interfaceunit>0</hub_playerinventory_interfaceunit>"))
  newTags.add(("hub_a1s4_complete", "<hub_a1s4_complete>0</hub_a1s4_complete>"))
  newTags.add(("last_scenario_console_group", "<last_scenario_console_group>5</last_scenario_console_group>"))
  newTags.add(("hub_a1s6_complete", "<hub_a1s6_complete>0</hub_a1s6_complete>"))
  newTags.add(("scenario_race_1_times_finished", "<scenario_race_1_times_finished>1</scenario_race_1_times_finished>"))
  newTags.add(("scenario_race_1_last_duration", "<scenario_race_1_last_duration>300.155</scenario_race_1_last_duration>"))
  newTags.add(("scenario_race_1_last_score", "<scenario_race_1_last_score>32332.494</scenario_race_1_last_score>"))
  newTags.add(("scenario_race_1_last_rating", "<scenario_race_1_last_rating>5</scenario_race_1_last_rating>"))
  newTags.add(("scenario_race_1_unlock_notified", "<scenario_race_1_unlock_notified>2</scenario_race_1_unlock_notified>"))
  newTags.add(("scenario_race_1_best_score", "<scenario_race_1_best_score>32332.494</scenario_race_1_best_score>"))
  newTags.add(("scenario_race_1_best_rating", "<scenario_race_1_best_rating>5</scenario_race_1_best_rating>"))
  newTags.add(("scenario_race_1_best_duration", "<scenario_race_1_best_duration>300.155</scenario_race_1_best_duration>"))
  newTags.add(("hub_a1s9_complete", "<hub_a1s9_complete>1</hub_a1s9_complete>"))
  newTags.add(("scenario_escort_1_times_finished", "<scenario_escort_1_times_finished>2</scenario_escort_1_times_finished>"))
  newTags.add(("scenario_escort_1_last_duration", "<scenario_escort_1_last_duration>1037.529</scenario_escort_1_last_duration>"))
  newTags.add(("scenario_escort_1_last_score", "<scenario_escort_1_last_score>865</scenario_escort_1_last_score>"))
  newTags.add(("scenario_escort_1_last_rating", "<scenario_escort_1_last_rating>5</scenario_escort_1_last_rating>"))
  newTags.add(("scenario_escort_1_unlock_notified", "<scenario_escort_1_unlock_notified>3</scenario_escort_1_unlock_notified>"))
  newTags.add(("scenario_escort_1_best_score", "<scenario_escort_1_best_score>865</scenario_escort_1_best_score>"))
  newTags.add(("scenario_escort_1_best_rating", "<scenario_escort_1_best_rating>5</scenario_escort_1_best_rating>"))
  newTags.add(("scenario_escort_1_best_duration", "<scenario_escort_1_best_duration>1037.529</scenario_escort_1_best_duration>"))
  newTags.add(("hub_a10s2_complete", "<hub_a10s2_complete>2</hub_a10s2_complete>"))
  newTags.add(("scenario_seek_and_destroy_times_finished", "<scenario_seek_and_destroy_times_finished>1</scenario_seek_and_destroy_times_finished>"))
  newTags.add(("scenario_seek_and_destroy_last_duration", "<scenario_seek_and_destroy_last_duration>600.01</scenario_seek_and_destroy_last_duration>"))
  newTags.add(("scenario_seek_and_destroy_last_score", "<scenario_seek_and_destroy_last_score>739.158</scenario_seek_and_destroy_last_score>"))
  newTags.add(("scenario_seek_and_destroy_last_rating", "<scenario_seek_and_destroy_last_rating>5</scenario_seek_and_destroy_last_rating>"))
  newTags.add(("scenario_seek_and_destroy_unlock_notified", "<scenario_seek_and_destroy_unlock_notified>1</scenario_seek_and_destroy_unlock_notified>"))
  newTags.add(("scenario_seek_and_destroy_best_score", "<scenario_seek_and_destroy_best_score>739.158</scenario_seek_and_destroy_best_score>"))
  newTags.add(("scenario_seek_and_destroy_best_rating", "<scenario_seek_and_destroy_best_rating>5</scenario_seek_and_destroy_best_rating>"))
  newTags.add(("scenario_seek_and_destroy_best_duration", "<scenario_seek_and_destroy_best_duration>600.01</scenario_seek_and_destroy_best_duration>"))
  newTags.add(("scenario_chapter_1_completed", "<scenario_chapter_1_completed>1</scenario_chapter_1_completed>"))
  newTags.add(("hub_a8s7_complete", "<hub_a8s7_complete>3</hub_a8s7_complete>"))
  newTags.add(("hub_a8s8_complete", "<hub_a8s8_complete>3</hub_a8s8_complete>"))
  newTags.add(("hub_a8s9_complete", "<hub_a8s9_complete>3</hub_a8s9_complete>"))
  newTags.add(("scenario_tharkas_cascade_times_finished", "<scenario_tharkas_cascade_times_finished>2</scenario_tharkas_cascade_times_finished>"))
  newTags.add(("scenario_tharkas_cascade_last_duration", "<scenario_tharkas_cascade_last_duration>415.614</scenario_tharkas_cascade_last_duration>"))
  newTags.add(("scenario_tharkas_cascade_last_score", "<scenario_tharkas_cascade_last_score>2097.241</scenario_tharkas_cascade_last_score>"))
  newTags.add(("scenario_tharkas_cascade_last_rating", "<scenario_tharkas_cascade_last_rating>5</scenario_tharkas_cascade_last_rating>"))
  newTags.add(("scenario_tharkas_cascade_unlock_notified", "<scenario_tharkas_cascade_unlock_notified>2</scenario_tharkas_cascade_unlock_notified>"))
  newTags.add(("scenario_tharkas_cascade_best_score", "<scenario_tharkas_cascade_best_score>2097.241</scenario_tharkas_cascade_best_score>"))
  newTags.add(("scenario_tharkas_cascade_best_rating", "<scenario_tharkas_cascade_best_rating>5</scenario_tharkas_cascade_best_rating>"))
  newTags.add(("scenario_tharkas_cascade_best_duration", "<scenario_tharkas_cascade_best_duration>415.614</scenario_tharkas_cascade_best_duration>"))
  newTags.add(("scenario_chapter_1_terminus_completed", "<scenario_chapter_1_terminus_completed>1</scenario_chapter_1_terminus_completed>"))
  newTags.add(("hub_a2s1_complete", "<hub_a2s1_complete>6</hub_a2s1_complete>"))
  newTags.add(("hub_a2s2_complete", "<hub_a2s2_complete>6</hub_a2s2_complete>"))
  newTags.add(("hub_a4s3_complete", "<hub_a4s3_complete>6</hub_a4s3_complete>"))
  newTags.add(("hub_a4s2_complete", "<hub_a4s2_complete>6</hub_a4s2_complete>"))
  newTags.add(("scenario_race_2_times_finished", "<scenario_race_2_times_finished>1</scenario_race_2_times_finished>"))
  newTags.add(("scenario_race_2_last_duration", "<scenario_race_2_last_duration>181.128</scenario_race_2_last_duration>"))
  newTags.add(("scenario_race_2_last_score", "<scenario_race_2_last_score>30333.588</scenario_race_2_last_score>"))
  newTags.add(("scenario_race_2_last_rating", "<scenario_race_2_last_rating>5</scenario_race_2_last_rating>"))
  newTags.add(("scenario_race_2_unlock_notified", "<scenario_race_2_unlock_notified>2</scenario_race_2_unlock_notified>"))
  newTags.add(("scenario_race_2_best_score", "<scenario_race_2_best_score>30333.588</scenario_race_2_best_score>"))
  newTags.add(("scenario_race_2_best_rating", "<scenario_race_2_best_rating>5</scenario_race_2_best_rating>"))
  newTags.add(("scenario_race_2_best_duration", "<scenario_race_2_best_duration>181.128</scenario_race_2_best_duration>"))
  newTags.add(("hub_a2s3_complete", "<hub_a2s3_complete>7</hub_a2s3_complete>"))
  newTags.add(("hub_a4s7_complete", "<hub_a4s7_complete>7</hub_a4s7_complete>"))
  newTags.add(("timelines_hub_hack_ch2_scenario_waveattack_1", "<timelines_hub_hack_ch2_scenario_waveattack_1>1</timelines_hub_hack_ch2_scenario_waveattack_1>"))
  newTags.add(("hub_a8s1_complete", "<hub_a8s1_complete>7</hub_a8s1_complete>"))
  newTags.add(("scenario_waveattack_1_times_finished", "<scenario_waveattack_1_times_finished>1</scenario_waveattack_1_times_finished>"))
  newTags.add(("scenario_waveattack_1_last_duration", "<scenario_waveattack_1_last_duration>1052.26</scenario_waveattack_1_last_duration>"))
  newTags.add(("scenario_waveattack_1_last_score", "<scenario_waveattack_1_last_score>686</scenario_waveattack_1_last_score>"))
  newTags.add(("scenario_waveattack_1_last_rating", "<scenario_waveattack_1_last_rating>5</scenario_waveattack_1_last_rating>"))
  newTags.add(("scenario_waveattack_1_unlock_notified", "<scenario_waveattack_1_unlock_notified>1</scenario_waveattack_1_unlock_notified>"))
  newTags.add(("scenario_waveattack_1_best_score", "<scenario_waveattack_1_best_score>686</scenario_waveattack_1_best_score>"))
  newTags.add(("scenario_waveattack_1_best_rating", "<scenario_waveattack_1_best_rating>5</scenario_waveattack_1_best_rating>"))
  newTags.add(("scenario_waveattack_1_best_duration", "<scenario_waveattack_1_best_duration>1052.26</scenario_waveattack_1_best_duration>"))
  newTags.add(("hub_a2s4_complete", "<hub_a2s4_complete>8</hub_a2s4_complete>"))
  newTags.add(("hub_a3s5_complete", "<hub_a3s5_complete>8</hub_a3s5_complete>"))
  newTags.add(("hub_a2s5_complete", "<hub_a2s5_complete>8</hub_a2s5_complete>"))
  newTags.add(("hub_a3s6_complete", "<hub_a3s6_complete>8</hub_a3s6_complete>"))
  newTags.add(("scenario_mining_2_times_finished", "<scenario_mining_2_times_finished>4</scenario_mining_2_times_finished>"))
  newTags.add(("scenario_mining_2_last_duration", "<scenario_mining_2_last_duration>307.511</scenario_mining_2_last_duration>"))
  newTags.add(("scenario_mining_2_last_score", "<scenario_mining_2_last_score>1594</scenario_mining_2_last_score>"))
  newTags.add(("scenario_mining_2_last_rating", "<scenario_mining_2_last_rating>5</scenario_mining_2_last_rating>"))
  newTags.add(("scenario_mining_2_unlock_notified", "<scenario_mining_2_unlock_notified>4</scenario_mining_2_unlock_notified>"))
  newTags.add(("scenario_mining_2_best_score", "<scenario_mining_2_best_score>1594</scenario_mining_2_best_score>"))
  newTags.add(("scenario_mining_2_best_rating", "<scenario_mining_2_best_rating>5</scenario_mining_2_best_rating>"))
  newTags.add(("scenario_mining_2_best_duration", "<scenario_mining_2_best_duration>307.511</scenario_mining_2_best_duration>"))
  newTags.add(("hub_a3s7_complete", "<hub_a3s7_complete>12</hub_a3s7_complete>"))
  newTags.add(("hub_a3s11_complete", "<hub_a3s11_complete>12</hub_a3s11_complete>"))
  newTags.add(("scenario_spacesuit_1_times_finished", "<scenario_spacesuit_1_times_finished>11</scenario_spacesuit_1_times_finished>"))
  newTags.add(("scenario_spacesuit_1_last_duration", "<scenario_spacesuit_1_last_duration>35.388</scenario_spacesuit_1_last_duration>"))
  newTags.add(("scenario_spacesuit_1_last_score", "<scenario_spacesuit_1_last_score>15339.325</scenario_spacesuit_1_last_score>"))
  newTags.add(("scenario_spacesuit_1_last_rating", "<scenario_spacesuit_1_last_rating>5</scenario_spacesuit_1_last_rating>"))
  newTags.add(("scenario_spacesuit_1_unlock_notified", "<scenario_spacesuit_1_unlock_notified>11</scenario_spacesuit_1_unlock_notified>"))
  newTags.add(("scenario_spacesuit_1_best_score", "<scenario_spacesuit_1_best_score>15339.325</scenario_spacesuit_1_best_score>"))
  newTags.add(("scenario_spacesuit_1_best_rating", "<scenario_spacesuit_1_best_rating>5</scenario_spacesuit_1_best_rating>"))
  newTags.add(("scenario_spacesuit_1_best_duration", "<scenario_spacesuit_1_best_duration>35.388</scenario_spacesuit_1_best_duration>"))
  newTags.add(("scenario_chapter_2_completed", "<scenario_chapter_2_completed>1</scenario_chapter_2_completed>"))
  newTags.add(("hub_a4s12_complete", "<hub_a4s12_complete>23</hub_a4s12_complete>"))
  newTags.add(("scenario_waveattack_antigone_times_finished", "<scenario_waveattack_antigone_times_finished>1</scenario_waveattack_antigone_times_finished>"))
  newTags.add(("scenario_waveattack_antigone_last_duration", "<scenario_waveattack_antigone_last_duration>1145.789</scenario_waveattack_antigone_last_duration>"))
  newTags.add(("scenario_waveattack_antigone_last_score", "<scenario_waveattack_antigone_last_score>715</scenario_waveattack_antigone_last_score>"))
  newTags.add(("scenario_waveattack_antigone_last_rating", "<scenario_waveattack_antigone_last_rating>5</scenario_waveattack_antigone_last_rating>"))
  newTags.add(("scenario_waveattack_antigone_unlock_notified", "<scenario_waveattack_antigone_unlock_notified>2</scenario_waveattack_antigone_unlock_notified>"))
  newTags.add(("scenario_waveattack_antigone_best_score", "<scenario_waveattack_antigone_best_score>715</scenario_waveattack_antigone_best_score>"))
  newTags.add(("scenario_waveattack_antigone_best_rating", "<scenario_waveattack_antigone_best_rating>5</scenario_waveattack_antigone_best_rating>"))
  newTags.add(("scenario_waveattack_antigone_best_duration", "<scenario_waveattack_antigone_best_duration>1145.789</scenario_waveattack_antigone_best_duration>"))
  newTags.add(("scenario_chapter_2_terminus_completed", "<scenario_chapter_2_terminus_completed>1</scenario_chapter_2_terminus_completed>"))
  newTags.add(("hub_a3s1_complete", "<hub_a3s1_complete>24</hub_a3s1_complete>"))
  newTags.add(("hub_a3s2_complete", "<hub_a3s2_complete>25</hub_a3s2_complete>"))
  newTags.add(("scenario_recruitment_1_times_finished", "<scenario_recruitment_1_times_finished>4</scenario_recruitment_1_times_finished>"))
  newTags.add(("scenario_recruitment_1_last_duration", "<scenario_recruitment_1_last_duration>53.602</scenario_recruitment_1_last_duration>"))
  newTags.add(("scenario_recruitment_1_last_score", "<scenario_recruitment_1_last_score>5</scenario_recruitment_1_last_score>"))
  newTags.add(("scenario_recruitment_1_last_rating", "<scenario_recruitment_1_last_rating>5</scenario_recruitment_1_last_rating>"))
  newTags.add(("scenario_recruitment_1_unlock_notified", "<scenario_recruitment_1_unlock_notified>4</scenario_recruitment_1_unlock_notified>"))
  newTags.add(("scenario_recruitment_1_best_score", "<scenario_recruitment_1_best_score>5</scenario_recruitment_1_best_score>"))
  newTags.add(("scenario_recruitment_1_best_rating", "<scenario_recruitment_1_best_rating>5</scenario_recruitment_1_best_rating>"))
  newTags.add(("scenario_recruitment_1_best_duration", "<scenario_recruitment_1_best_duration>53.602</scenario_recruitment_1_best_duration>"))
  newTags.add(("hub_a3s3_complete", "<hub_a3s3_complete>28</hub_a3s3_complete>"))
  newTags.add(("hub_a4s4_complete", "<hub_a4s4_complete>28</hub_a4s4_complete>"))
  newTags.add(("scenario_race_3_times_finished", "<scenario_race_3_times_finished>1</scenario_race_3_times_finished>"))
  newTags.add(("scenario_race_3_last_duration", "<scenario_race_3_last_duration>141.823</scenario_race_3_last_duration>"))
  newTags.add(("scenario_race_3_last_score", "<scenario_race_3_last_score>35118.352</scenario_race_3_last_score>"))
  newTags.add(("scenario_race_3_last_rating", "<scenario_race_3_last_rating>5</scenario_race_3_last_rating>"))
  newTags.add(("scenario_race_3_unlock_notified", "<scenario_race_3_unlock_notified>2</scenario_race_3_unlock_notified>"))
  newTags.add(("scenario_race_3_best_score", "<scenario_race_3_best_score>35118.352</scenario_race_3_best_score>"))
  newTags.add(("scenario_race_3_best_rating", "<scenario_race_3_best_rating>5</scenario_race_3_best_rating>"))
  newTags.add(("scenario_race_3_best_duration", "<scenario_race_3_best_duration>141.823</scenario_race_3_best_duration>"))
  newTags.add(("hub_a3s4_complete", "<hub_a3s4_complete>29</hub_a3s4_complete>"))
  newTags.add(("hub_a4s5_complete", "<hub_a4s5_complete>29</hub_a4s5_complete>"))
  newTags.add(("hub_a10s5_complete", "<hub_a10s5_complete>29</hub_a10s5_complete>"))
  newTags.add(("hub_a10s7_complete", "<hub_a10s7_complete>29</hub_a10s7_complete>"))
  newTags.add(("hub_a10s8_complete", "<hub_a10s8_complete>29</hub_a10s8_complete>"))
  newTags.add(("hub_a10s6_complete", "<hub_a10s6_complete>29</hub_a10s6_complete>"))
  newTags.add(("timelines_hub_hack_ch3_scenario_mining_4", "<timelines_hub_hack_ch3_scenario_mining_4>1</timelines_hub_hack_ch3_scenario_mining_4>"))
  newTags.add(("hub_a8s2_complete", "<hub_a8s2_complete>29</hub_a8s2_complete>"))
  newTags.add(("scenario_mining_4_times_finished", "<scenario_mining_4_times_finished>1</scenario_mining_4_times_finished>"))
  newTags.add(("scenario_mining_4_last_duration", "<scenario_mining_4_last_duration>604.016</scenario_mining_4_last_duration>"))
  newTags.add(("scenario_mining_4_last_score", "<scenario_mining_4_last_score>6251</scenario_mining_4_last_score>"))
  newTags.add(("scenario_mining_4_last_rating", "<scenario_mining_4_last_rating>5</scenario_mining_4_last_rating>"))
  newTags.add(("scenario_mining_4_unlock_notified", "<scenario_mining_4_unlock_notified>1</scenario_mining_4_unlock_notified>"))
  newTags.add(("scenario_mining_4_best_score", "<scenario_mining_4_best_score>6251</scenario_mining_4_best_score>"))
  newTags.add(("scenario_mining_4_best_rating", "<scenario_mining_4_best_rating>5</scenario_mining_4_best_rating>"))
  newTags.add(("scenario_mining_4_best_duration", "<scenario_mining_4_best_duration>604.016</scenario_mining_4_best_duration>"))
  newTags.add(("hub_a3s8_complete", "<hub_a3s8_complete>30</hub_a3s8_complete>"))
  newTags.add(("hub_a5s1_complete", "<hub_a5s1_complete>30</hub_a5s1_complete>"))
  newTags.add(("scenario_assassinate_times_finished", "<scenario_assassinate_times_finished>4</scenario_assassinate_times_finished>"))
  newTags.add(("scenario_assassinate_last_duration", "<scenario_assassinate_last_duration>258.312</scenario_assassinate_last_duration>"))
  newTags.add(("scenario_assassinate_last_score", "<scenario_assassinate_last_score>2145.679</scenario_assassinate_last_score>"))
  newTags.add(("scenario_assassinate_last_rating", "<scenario_assassinate_last_rating>5</scenario_assassinate_last_rating>"))
  newTags.add(("scenario_assassinate_unlock_notified", "<scenario_assassinate_unlock_notified>4</scenario_assassinate_unlock_notified>"))
  newTags.add(("scenario_assassinate_best_score", "<scenario_assassinate_best_score>2145.679</scenario_assassinate_best_score>"))
  newTags.add(("scenario_assassinate_best_rating", "<scenario_assassinate_best_rating>5</scenario_assassinate_best_rating>"))
  newTags.add(("scenario_assassinate_best_duration", "<scenario_assassinate_best_duration>258.312</scenario_assassinate_best_duration>"))
  newTags.add(("hub_a3s9_complete", "<hub_a3s9_complete>34</hub_a3s9_complete>"))
  newTags.add(("fleetbattle1_argon", "<fleetbattle1_argon>1</fleetbattle1_argon>"))
  newTags.add(("scenario_fleet_battle_1_times_finished", "<scenario_fleet_battle_1_times_finished>1</scenario_fleet_battle_1_times_finished>"))
  newTags.add(("scenario_fleet_battle_1_last_duration", "<scenario_fleet_battle_1_last_duration>637.209</scenario_fleet_battle_1_last_duration>"))
  newTags.add(("scenario_fleet_battle_1_last_score", "<scenario_fleet_battle_1_last_score>1118</scenario_fleet_battle_1_last_score>"))
  newTags.add(("scenario_fleet_battle_1_last_rating", "<scenario_fleet_battle_1_last_rating>5</scenario_fleet_battle_1_last_rating>"))
  newTags.add(("scenario_fleet_battle_1_unlock_notified", "<scenario_fleet_battle_1_unlock_notified>1</scenario_fleet_battle_1_unlock_notified>"))
  newTags.add(("scenario_fleet_battle_1_best_score", "<scenario_fleet_battle_1_best_score>1118</scenario_fleet_battle_1_best_score>"))
  newTags.add(("scenario_fleet_battle_1_best_rating", "<scenario_fleet_battle_1_best_rating>5</scenario_fleet_battle_1_best_rating>"))
  newTags.add(("scenario_fleet_battle_1_best_duration", "<scenario_fleet_battle_1_best_duration>637.209</scenario_fleet_battle_1_best_duration>"))
  newTags.add(("scenario_chapter_3_completed", "<scenario_chapter_3_completed>1</scenario_chapter_3_completed>"))
  newTags.add(("hub_a3s10_complete", "<hub_a3s10_complete>35</hub_a3s10_complete>"))
  newTags.add(("hub_a3s12_complete", "<hub_a3s12_complete>35</hub_a3s12_complete>"))
  newTags.add(("hub_a3s13_complete", "<hub_a3s13_complete>35</hub_a3s13_complete>"))
  newTags.add(("hub_a4s8_complete", "<hub_a4s8_complete>35</hub_a4s8_complete>"))
  newTags.add(("scenario_m0_boss_battle_times_finished", "<scenario_m0_boss_battle_times_finished>2</scenario_m0_boss_battle_times_finished>"))
  newTags.add(("scenario_m0_boss_battle_last_duration", "<scenario_m0_boss_battle_last_duration>1090.594</scenario_m0_boss_battle_last_duration>"))
  newTags.add(("scenario_m0_boss_battle_last_score", "<scenario_m0_boss_battle_last_score>1720</scenario_m0_boss_battle_last_score>"))
  newTags.add(("scenario_m0_boss_battle_last_rating", "<scenario_m0_boss_battle_last_rating>5</scenario_m0_boss_battle_last_rating>"))
  newTags.add(("scenario_m0_boss_battle_unlock_notified", "<scenario_m0_boss_battle_unlock_notified>2</scenario_m0_boss_battle_unlock_notified>"))
  newTags.add(("scenario_m0_boss_battle_best_score", "<scenario_m0_boss_battle_best_score>1720</scenario_m0_boss_battle_best_score>"))
  newTags.add(("scenario_m0_boss_battle_best_rating", "<scenario_m0_boss_battle_best_rating>5</scenario_m0_boss_battle_best_rating>"))
  newTags.add(("scenario_m0_boss_battle_best_duration", "<scenario_m0_boss_battle_best_duration>1090.594</scenario_m0_boss_battle_best_duration>"))
  newTags.add(("scenario_chapter_3_terminus_completed", "<scenario_chapter_3_terminus_completed>1</scenario_chapter_3_terminus_completed>"))
  newTags.add(("hub_a4s1_complete", "<hub_a4s1_complete>37</hub_a4s1_complete>"))
  newTags.add(("scenario_mining_1_times_finished", "<scenario_mining_1_times_finished>2</scenario_mining_1_times_finished>"))
  newTags.add(("scenario_mining_1_last_duration", "<scenario_mining_1_last_duration>65.4927</scenario_mining_1_last_duration>"))
  newTags.add(("scenario_mining_1_last_score", "<scenario_mining_1_last_score>101</scenario_mining_1_last_score>"))
  newTags.add(("scenario_mining_1_last_rating", "<scenario_mining_1_last_rating>5</scenario_mining_1_last_rating>"))
  newTags.add(("scenario_mining_1_unlock_notified", "<scenario_mining_1_unlock_notified>2</scenario_mining_1_unlock_notified>"))
  newTags.add(("scenario_mining_1_best_score", "<scenario_mining_1_best_score>101</scenario_mining_1_best_score>"))
  newTags.add(("scenario_mining_1_best_rating", "<scenario_mining_1_best_rating>5</scenario_mining_1_best_rating>"))
  newTags.add(("scenario_mining_1_best_duration", "<scenario_mining_1_best_duration>65.4927</scenario_mining_1_best_duration>"))
  newTags.add(("hub_a4s6_complete", "<hub_a4s6_complete>39</hub_a4s6_complete>"))
  newTags.add(("timelines_hub_hack_ch4_scenario_trading_1", "<timelines_hub_hack_ch4_scenario_trading_1>1</timelines_hub_hack_ch4_scenario_trading_1>"))
  newTags.add(("hub_a8s3_complete", "<hub_a8s3_complete>39</hub_a8s3_complete>"))
  newTags.add(("scenario_trading_1_times_finished", "<scenario_trading_1_times_finished>1</scenario_trading_1_times_finished>"))
  newTags.add(("scenario_trading_1_last_duration", "<scenario_trading_1_last_duration>542.187</scenario_trading_1_last_duration>"))
  newTags.add(("scenario_trading_1_last_score", "<scenario_trading_1_last_score>1858.54</scenario_trading_1_last_score>"))
  newTags.add(("scenario_trading_1_last_rating", "<scenario_trading_1_last_rating>5</scenario_trading_1_last_rating>"))
  newTags.add(("scenario_trading_1_unlock_notified", "<scenario_trading_1_unlock_notified>1</scenario_trading_1_unlock_notified>"))
  newTags.add(("scenario_trading_1_best_score", "<scenario_trading_1_best_score>1858.54</scenario_trading_1_best_score>"))
  newTags.add(("scenario_trading_1_best_rating", "<scenario_trading_1_best_rating>5</scenario_trading_1_best_rating>"))
  newTags.add(("scenario_trading_1_best_duration", "<scenario_trading_1_best_duration>542.187</scenario_trading_1_best_duration>"))
  newTags.add(("hub_a4s9_complete", "<hub_a4s9_complete>40</hub_a4s9_complete>"))
  newTags.add(("scenario_spacesuit_2_times_finished", "<scenario_spacesuit_2_times_finished>8</scenario_spacesuit_2_times_finished>"))
  newTags.add(("scenario_spacesuit_2_last_duration", "<scenario_spacesuit_2_last_duration>308.441</scenario_spacesuit_2_last_duration>"))
  newTags.add(("scenario_spacesuit_2_last_score", "<scenario_spacesuit_2_last_score>3300</scenario_spacesuit_2_last_score>"))
  newTags.add(("scenario_spacesuit_2_last_rating", "<scenario_spacesuit_2_last_rating>4</scenario_spacesuit_2_last_rating>"))
  newTags.add(("scenario_spacesuit_2_unlock_notified", "<scenario_spacesuit_2_unlock_notified>8</scenario_spacesuit_2_unlock_notified>"))
  newTags.add(("scenario_spacesuit_2_best_score", "<scenario_spacesuit_2_best_score>3500</scenario_spacesuit_2_best_score>"))
  newTags.add(("scenario_spacesuit_2_best_rating", "<scenario_spacesuit_2_best_rating>5</scenario_spacesuit_2_best_rating>"))
  newTags.add(("scenario_spacesuit_2_best_duration", "<scenario_spacesuit_2_best_duration>310.36</scenario_spacesuit_2_best_duration>"))
  newTags.add(("hub_a4s10_complete", "<hub_a4s10_complete>42</hub_a4s10_complete>"))
  newTags.add(("hub_a5s3_complete", "<hub_a5s3_complete>42</hub_a5s3_complete>"))
  newTags.add(("hub_a9s1_complete", "<hub_a9s1_complete>42</hub_a9s1_complete>"))
  newTags.add(("hub_playerinventory_cosmeticskit", "<hub_playerinventory_cosmeticskit>0</hub_playerinventory_cosmeticskit>"))
  newTags.add(("hub_playerinventory_fieldarray", "<hub_playerinventory_fieldarray>0</hub_playerinventory_fieldarray>"))
  newTags.add(("hub_a9s2_complete", "<hub_a9s2_complete>42</hub_a9s2_complete>"))
  newTags.add(("hub_a9s3_complete", "<hub_a9s3_complete>42</hub_a9s3_complete>"))
  newTags.add(("scenario_weaken_station_times_finished", "<scenario_weaken_station_times_finished>1</scenario_weaken_station_times_finished>"))
  newTags.add(("scenario_weaken_station_last_duration", "<scenario_weaken_station_last_duration>228.893</scenario_weaken_station_last_duration>"))
  newTags.add(("scenario_weaken_station_last_score", "<scenario_weaken_station_last_score>2013.172</scenario_weaken_station_last_score>"))
  newTags.add(("scenario_weaken_station_last_rating", "<scenario_weaken_station_last_rating>5</scenario_weaken_station_last_rating>"))
  newTags.add(("scenario_weaken_station_unlock_notified", "<scenario_weaken_station_unlock_notified>1</scenario_weaken_station_unlock_notified>"))
  newTags.add(("scenario_weaken_station_best_score", "<scenario_weaken_station_best_score>2013.172</scenario_weaken_station_best_score>"))
  newTags.add(("scenario_weaken_station_best_rating", "<scenario_weaken_station_best_rating>5</scenario_weaken_station_best_rating>"))
  newTags.add(("scenario_weaken_station_best_duration", "<scenario_weaken_station_best_duration>228.893</scenario_weaken_station_best_duration>"))
  newTags.add(("scenario_weaken_fleet_times_finished", "<scenario_weaken_fleet_times_finished>1</scenario_weaken_fleet_times_finished>"))
  newTags.add(("scenario_weaken_fleet_last_duration", "<scenario_weaken_fleet_last_duration>180.971</scenario_weaken_fleet_last_duration>"))
  newTags.add(("scenario_weaken_fleet_last_score", "<scenario_weaken_fleet_last_score>1069.783</scenario_weaken_fleet_last_score>"))
  newTags.add(("scenario_weaken_fleet_last_rating", "<scenario_weaken_fleet_last_rating>5</scenario_weaken_fleet_last_rating>"))
  newTags.add(("scenario_weaken_fleet_unlock_notified", "<scenario_weaken_fleet_unlock_notified>1</scenario_weaken_fleet_unlock_notified>"))
  newTags.add(("scenario_weaken_fleet_best_score", "<scenario_weaken_fleet_best_score>1069.783</scenario_weaken_fleet_best_score>"))
  newTags.add(("scenario_weaken_fleet_best_rating", "<scenario_weaken_fleet_best_rating>5</scenario_weaken_fleet_best_rating>"))
  newTags.add(("scenario_weaken_fleet_best_duration", "<scenario_weaken_fleet_best_duration>180.971</scenario_weaken_fleet_best_duration>"))
  newTags.add(("scenario_chapter_4_completed", "<scenario_chapter_4_completed>1</scenario_chapter_4_completed>"))
  newTags.add(("timelines_presidents_end_blackbox", "<timelines_presidents_end_blackbox>1</timelines_presidents_end_blackbox>"))
  newTags.add(("timelines_presidents_end_transmit", "<timelines_presidents_end_transmit>1</timelines_presidents_end_transmit>"))
  newTags.add(("scenario_presidents_end_1_times_finished", "<scenario_presidents_end_1_times_finished>1</scenario_presidents_end_1_times_finished>"))
  newTags.add(("scenario_presidents_end_1_last_duration", "<scenario_presidents_end_1_last_duration>1093.557</scenario_presidents_end_1_last_duration>"))
  newTags.add(("scenario_presidents_end_1_last_score", "<scenario_presidents_end_1_last_score>443</scenario_presidents_end_1_last_score>"))
  newTags.add(("scenario_presidents_end_1_last_rating", "<scenario_presidents_end_1_last_rating>5</scenario_presidents_end_1_last_rating>"))
  newTags.add(("scenario_presidents_end_1_unlock_notified", "<scenario_presidents_end_1_unlock_notified>1</scenario_presidents_end_1_unlock_notified>"))
  newTags.add(("scenario_presidents_end_1_best_score", "<scenario_presidents_end_1_best_score>443</scenario_presidents_end_1_best_score>"))
  newTags.add(("scenario_presidents_end_1_best_rating", "<scenario_presidents_end_1_best_rating>5</scenario_presidents_end_1_best_rating>"))
  newTags.add(("scenario_presidents_end_1_best_duration", "<scenario_presidents_end_1_best_duration>1093.557</scenario_presidents_end_1_best_duration>"))
  newTags.add(("scenario_chapter_4_terminus_completed", "<scenario_chapter_4_terminus_completed>1</scenario_chapter_4_terminus_completed>"))
  newTags.add(("scenario_mining_3_times_finished", "<scenario_mining_3_times_finished>1</scenario_mining_3_times_finished>"))
  newTags.add(("scenario_mining_3_last_duration", "<scenario_mining_3_last_duration>935.697</scenario_mining_3_last_duration>"))
  newTags.add(("scenario_mining_3_last_score", "<scenario_mining_3_last_score>6270</scenario_mining_3_last_score>"))
  newTags.add(("scenario_mining_3_last_rating", "<scenario_mining_3_last_rating>5</scenario_mining_3_last_rating>"))
  newTags.add(("scenario_mining_3_unlock_notified", "<scenario_mining_3_unlock_notified>1</scenario_mining_3_unlock_notified>"))
  newTags.add(("scenario_mining_3_best_score", "<scenario_mining_3_best_score>6270</scenario_mining_3_best_score>"))
  newTags.add(("scenario_mining_3_best_rating", "<scenario_mining_3_best_rating>5</scenario_mining_3_best_rating>"))
  newTags.add(("scenario_mining_3_best_duration", "<scenario_mining_3_best_duration>935.697</scenario_mining_3_best_duration>"))
  newTags.add(("scenario_trading_2_times_finished", "<scenario_trading_2_times_finished>2</scenario_trading_2_times_finished>"))
  newTags.add(("scenario_trading_2_last_duration", "<scenario_trading_2_last_duration>1096.252</scenario_trading_2_last_duration>"))
  newTags.add(("scenario_trading_2_last_score", "<scenario_trading_2_last_score>3829</scenario_trading_2_last_score>"))
  newTags.add(("scenario_trading_2_last_rating", "<scenario_trading_2_last_rating>5</scenario_trading_2_last_rating>"))
  newTags.add(("scenario_trading_2_unlock_notified", "<scenario_trading_2_unlock_notified>2</scenario_trading_2_unlock_notified>"))
  newTags.add(("scenario_trading_2_best_score", "<scenario_trading_2_best_score>3829</scenario_trading_2_best_score>"))
  newTags.add(("scenario_trading_2_best_rating", "<scenario_trading_2_best_rating>5</scenario_trading_2_best_rating>"))
  newTags.add(("scenario_trading_2_best_duration", "<scenario_trading_2_best_duration>1096.252</scenario_trading_2_best_duration>"))
  newTags.add(("scenario_spacesuit_3_times_finished", "<scenario_spacesuit_3_times_finished>5</scenario_spacesuit_3_times_finished>"))
  newTags.add(("scenario_spacesuit_3_last_duration", "<scenario_spacesuit_3_last_duration>123.413</scenario_spacesuit_3_last_duration>"))
  newTags.add(("scenario_spacesuit_3_last_score", "<scenario_spacesuit_3_last_score>6106.963</scenario_spacesuit_3_last_score>"))
  newTags.add(("scenario_spacesuit_3_last_rating", "<scenario_spacesuit_3_last_rating>5</scenario_spacesuit_3_last_rating>"))
  newTags.add(("scenario_spacesuit_3_unlock_notified", "<scenario_spacesuit_3_unlock_notified>5</scenario_spacesuit_3_unlock_notified>"))
  newTags.add(("scenario_spacesuit_3_best_score", "<scenario_spacesuit_3_best_score>6106.963</scenario_spacesuit_3_best_score>"))
  newTags.add(("scenario_spacesuit_3_best_rating", "<scenario_spacesuit_3_best_rating>5</scenario_spacesuit_3_best_rating>"))
  newTags.add(("scenario_spacesuit_3_best_duration", "<scenario_spacesuit_3_best_duration>123.413</scenario_spacesuit_3_best_duration>"))
  newTags.add(("scenario_disable_capship_times_finished", "<scenario_disable_capship_times_finished>1</scenario_disable_capship_times_finished>"))
  newTags.add(("scenario_disable_capship_last_duration", "<scenario_disable_capship_last_duration>189.961</scenario_disable_capship_last_duration>"))
  newTags.add(("scenario_disable_capship_last_score", "<scenario_disable_capship_last_score>1589.794</scenario_disable_capship_last_score>"))
  newTags.add(("scenario_disable_capship_last_rating", "<scenario_disable_capship_last_rating>5</scenario_disable_capship_last_rating>"))
  newTags.add(("scenario_disable_capship_unlock_notified", "<scenario_disable_capship_unlock_notified>1</scenario_disable_capship_unlock_notified>"))
  newTags.add(("scenario_disable_capship_best_score", "<scenario_disable_capship_best_score>1589.794</scenario_disable_capship_best_score>"))
  newTags.add(("scenario_disable_capship_best_rating", "<scenario_disable_capship_best_rating>5</scenario_disable_capship_best_rating>"))
  newTags.add(("scenario_disable_capship_best_duration", "<scenario_disable_capship_best_duration>189.961</scenario_disable_capship_best_duration>"))
  newTags.add(("scenario_chapter_5_completed", "<scenario_chapter_5_completed>1</scenario_chapter_5_completed>"))
  newTags.add(("scenario_khaak_boss_battle_times_finished", "<scenario_khaak_boss_battle_times_finished>3</scenario_khaak_boss_battle_times_finished>"))
  newTags.add(("scenario_khaak_boss_battle_last_duration", "<scenario_khaak_boss_battle_last_duration>437.465</scenario_khaak_boss_battle_last_duration>"))
  newTags.add(("scenario_khaak_boss_battle_last_score", "<scenario_khaak_boss_battle_last_score>1042.838</scenario_khaak_boss_battle_last_score>"))
  newTags.add(("scenario_khaak_boss_battle_last_rating", "<scenario_khaak_boss_battle_last_rating>5</scenario_khaak_boss_battle_last_rating>"))
  newTags.add(("scenario_khaak_boss_battle_unlock_notified", "<scenario_khaak_boss_battle_unlock_notified>3</scenario_khaak_boss_battle_unlock_notified>"))
  newTags.add(("scenario_khaak_boss_battle_best_score", "<scenario_khaak_boss_battle_best_score>1042.838</scenario_khaak_boss_battle_best_score>"))
  newTags.add(("scenario_khaak_boss_battle_best_rating", "<scenario_khaak_boss_battle_best_rating>5</scenario_khaak_boss_battle_best_rating>"))
  newTags.add(("scenario_khaak_boss_battle_best_duration", "<scenario_khaak_boss_battle_best_duration>437.465</scenario_khaak_boss_battle_best_duration>"))
  newTags.add(("scenario_chapter_5_terminus_completed", "<scenario_chapter_5_terminus_completed>1</scenario_chapter_5_terminus_completed>"))
  newTags.add(("scenario_trading_3_times_finished", "<scenario_trading_3_times_finished>1</scenario_trading_3_times_finished>"))
  newTags.add(("scenario_trading_3_last_duration", "<scenario_trading_3_last_duration>507.276</scenario_trading_3_last_duration>"))
  newTags.add(("scenario_trading_3_last_score", "<scenario_trading_3_last_score>2198.63</scenario_trading_3_last_score>"))
  newTags.add(("scenario_trading_3_last_rating", "<scenario_trading_3_last_rating>5</scenario_trading_3_last_rating>"))
  newTags.add(("scenario_trading_3_unlock_notified", "<scenario_trading_3_unlock_notified>1</scenario_trading_3_unlock_notified>"))
  newTags.add(("scenario_trading_3_best_score", "<scenario_trading_3_best_score>2198.63</scenario_trading_3_best_score>"))
  newTags.add(("scenario_trading_3_best_rating", "<scenario_trading_3_best_rating>5</scenario_trading_3_best_rating>"))
  newTags.add(("scenario_trading_3_best_duration", "<scenario_trading_3_best_duration>507.276</scenario_trading_3_best_duration>"))
  newTags.add(("scenario_mining_7_times_finished", "<scenario_mining_7_times_finished>1</scenario_mining_7_times_finished>"))
  newTags.add(("scenario_mining_7_last_duration", "<scenario_mining_7_last_duration>3383.07</scenario_mining_7_last_duration>"))
  newTags.add(("scenario_mining_7_last_score", "<scenario_mining_7_last_score>8372</scenario_mining_7_last_score>"))
  newTags.add(("scenario_mining_7_last_rating", "<scenario_mining_7_last_rating>5</scenario_mining_7_last_rating>"))
  newTags.add(("scenario_mining_7_unlock_notified", "<scenario_mining_7_unlock_notified>1</scenario_mining_7_unlock_notified>"))
  newTags.add(("scenario_mining_7_best_score", "<scenario_mining_7_best_score>8372</scenario_mining_7_best_score>"))
  newTags.add(("scenario_mining_7_best_rating", "<scenario_mining_7_best_rating>5</scenario_mining_7_best_rating>"))
  newTags.add(("scenario_mining_7_best_duration", "<scenario_mining_7_best_duration>3383.07</scenario_mining_7_best_duration>"))
  newTags.add(("scenario_protect_object_times_finished", "<scenario_protect_object_times_finished>2</scenario_protect_object_times_finished>"))
  newTags.add(("scenario_protect_object_last_duration", "<scenario_protect_object_last_duration>1370.711</scenario_protect_object_last_duration>"))
  newTags.add(("scenario_protect_object_last_score", "<scenario_protect_object_last_score>217.922</scenario_protect_object_last_score>"))
  newTags.add(("scenario_protect_object_last_rating", "<scenario_protect_object_last_rating>5</scenario_protect_object_last_rating>"))
  newTags.add(("scenario_protect_object_unlock_notified", "<scenario_protect_object_unlock_notified>2</scenario_protect_object_unlock_notified>"))
  newTags.add(("scenario_protect_object_best_score", "<scenario_protect_object_best_score>217.922</scenario_protect_object_best_score>"))
  newTags.add(("scenario_protect_object_best_rating", "<scenario_protect_object_best_rating>5</scenario_protect_object_best_rating>"))
  newTags.add(("scenario_protect_object_best_duration", "<scenario_protect_object_best_duration>1370.711</scenario_protect_object_best_duration>"))
  newTags.add(("scenario_fleet_battle_2_times_finished", "<scenario_fleet_battle_2_times_finished>1</scenario_fleet_battle_2_times_finished>"))
  newTags.add(("scenario_fleet_battle_2_last_duration", "<scenario_fleet_battle_2_last_duration>1148.215</scenario_fleet_battle_2_last_duration>"))
  newTags.add(("scenario_fleet_battle_2_last_score", "<scenario_fleet_battle_2_last_score>5548.92</scenario_fleet_battle_2_last_score>"))
  newTags.add(("scenario_fleet_battle_2_last_rating", "<scenario_fleet_battle_2_last_rating>5</scenario_fleet_battle_2_last_rating>"))
  newTags.add(("scenario_fleet_battle_2_unlock_notified", "<scenario_fleet_battle_2_unlock_notified>1</scenario_fleet_battle_2_unlock_notified>"))
  newTags.add(("scenario_fleet_battle_2_best_score", "<scenario_fleet_battle_2_best_score>5548.92</scenario_fleet_battle_2_best_score>"))
  newTags.add(("scenario_fleet_battle_2_best_rating", "<scenario_fleet_battle_2_best_rating>5</scenario_fleet_battle_2_best_rating>"))
  newTags.add(("scenario_fleet_battle_2_best_duration", "<scenario_fleet_battle_2_best_duration>1148.215</scenario_fleet_battle_2_best_duration>"))
  newTags.add(("scenario_spacesuit_4_times_finished", "<scenario_spacesuit_4_times_finished>7</scenario_spacesuit_4_times_finished>"))
  newTags.add(("scenario_spacesuit_4_last_duration", "<scenario_spacesuit_4_last_duration>275.121</scenario_spacesuit_4_last_duration>"))
  newTags.add(("scenario_spacesuit_4_last_score", "<scenario_spacesuit_4_last_score>2000.234</scenario_spacesuit_4_last_score>"))
  newTags.add(("scenario_spacesuit_4_last_rating", "<scenario_spacesuit_4_last_rating>5</scenario_spacesuit_4_last_rating>"))
  newTags.add(("scenario_spacesuit_4_best_score", "<scenario_spacesuit_4_best_score>2000.234</scenario_spacesuit_4_best_score>"))
  newTags.add(("scenario_spacesuit_4_best_rating", "<scenario_spacesuit_4_best_rating>5</scenario_spacesuit_4_best_rating>"))
  newTags.add(("scenario_spacesuit_4_best_duration", "<scenario_spacesuit_4_best_duration>255.121</scenario_spacesuit_4_best_duration>"))
  newTags.add(("scenario_chapter_6_completed", "<scenario_chapter_6_completed>1</scenario_chapter_6_completed>"))
  newTags.add(("scenario_spacesuit_4_unlock_notified", "<scenario_spacesuit_4_unlock_notified>5</scenario_spacesuit_4_unlock_notified>"))
  newTags.add(("timelines_hub_hack_ch6_scenario_dragonfyre", "<timelines_hub_hack_ch6_scenario_dragonfyre>1</timelines_hub_hack_ch6_scenario_dragonfyre>"))
  newTags.add(("hub_a5s4_complete", "<hub_a5s4_complete>75</hub_a5s4_complete>"))
  newTags.add(("scenario_dragonfyre_times_finished", "<scenario_dragonfyre_times_finished>1</scenario_dragonfyre_times_finished>"))
  newTags.add(("scenario_dragonfyre_last_duration", "<scenario_dragonfyre_last_duration>1014.997</scenario_dragonfyre_last_duration>"))
  newTags.add(("scenario_dragonfyre_last_score", "<scenario_dragonfyre_last_score>2784</scenario_dragonfyre_last_score>"))
  newTags.add(("scenario_dragonfyre_last_rating", "<scenario_dragonfyre_last_rating>5</scenario_dragonfyre_last_rating>"))
  newTags.add(("scenario_dragonfyre_unlock_notified", "<scenario_dragonfyre_unlock_notified>2</scenario_dragonfyre_unlock_notified>"))
  newTags.add(("scenario_dragonfyre_best_score", "<scenario_dragonfyre_best_score>2784</scenario_dragonfyre_best_score>"))
  newTags.add(("scenario_dragonfyre_best_rating", "<scenario_dragonfyre_best_rating>5</scenario_dragonfyre_best_rating>"))
  newTags.add(("scenario_dragonfyre_best_duration", "<scenario_dragonfyre_best_duration>1014.997</scenario_dragonfyre_best_duration>"))
  newTags.add(("scenario_chapter_6_terminus_completed", "<scenario_chapter_6_terminus_completed>1</scenario_chapter_6_terminus_completed>"))
  newTags.add(("hub_a6s1_complete", "<hub_a6s1_complete>76</hub_a6s1_complete>"))
  newTags.add(("hub_a6s2_complete", "<hub_a6s2_complete>76</hub_a6s2_complete>"))
  newTags.add(("hub_a6s3_complete", "<hub_a6s3_complete>76</hub_a6s3_complete>"))
  newTags.add(("hub_a6s4_complete", "<hub_a6s4_complete>76</hub_a6s4_complete>"))
  newTags.add(("hub_a7s3_complete", "<hub_a7s3_complete>76</hub_a7s3_complete>"))
  newTags.add(("hub_a7s2_complete", "<hub_a7s2_complete>76</hub_a7s2_complete>"))
  newTags.add(("hub_a7s4_complete", "<hub_a7s4_complete>76</hub_a7s4_complete>"))
  newTags.add(("hub_a7s5_complete", "<hub_a7s5_complete>76</hub_a7s5_complete>"))
  newTags.add(("hub_a7s1_complete", "<hub_a7s1_complete>76</hub_a7s1_complete>"))

  let updatedContent = updateTags(content, newTags)

  try:
    writeFile(filePath, updatedContent)
    echo "\nSUCCESS: userdata.xml updated successfully!"
    echo "All Timelines content has been unlocked."
    echo "\nPress Enter to exit..."
    discard readLine(stdin)
  except:
    echo "ERROR writing file"
    echo "\nPress Enter to exit..."
    discard readLine(stdin)

main()
