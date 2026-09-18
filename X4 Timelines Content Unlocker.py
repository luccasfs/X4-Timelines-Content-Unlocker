import os
import shutil
import re
import winreg
from datetime import datetime

def find_userdata():
    """Find the X4 userdata.xml file, supporting OneDrive, nested Desktop folders, and custom locations"""
    possible_paths = []

    # 1. Tenta pegar a pasta Documents registrada no Windows
    try:
        with winreg.OpenKey(winreg.HKEY_CURRENT_USER, r"Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders") as key:
            docs_path = winreg.QueryValueEx(key, "Personal")[0]
            docs_path = os.path.expandvars(docs_path)
            possible_paths.append(os.path.join(docs_path, 'Egosoft', 'X4'))
    except Exception:
        pass

    home = os.path.expanduser('~')
    onedrive = os.environ.get('OneDrive') or os.path.join(home, 'OneDrive')

    # 2. Lista de caminhos conhecidos (incluindo o caso de Documentos dentro do Desktop)
    candidate_bases = [
        os.path.join(onedrive, 'Desktop', 'Documents'),
        os.path.join(onedrive, 'Documents'),
        os.path.join(home, 'Desktop', 'Documents'),
        os.path.join(home, 'Documents'),
    ]

    for base in candidate_bases:
        possible_paths.append(os.path.join(base, 'Egosoft', 'X4'))

    # 3. Varre os caminhos e busca a pasta com userdata.xml
    checked = set()
    for base_path in possible_paths:
        if base_path in checked:
            continue
        checked.add(base_path)

        if os.path.exists(base_path):
            for folder in os.listdir(base_path):
                full_folder = os.path.join(base_path, folder)
                if os.path.isdir(full_folder):
                    userdata = os.path.join(full_folder, 'userdata.xml')
                    if os.path.exists(userdata):
                        return userdata

    print("ERROR: userdata.xml not found in X4 subfolders")
    return None

def make_backup(file_path):
    """Create a backup of the file"""
    timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
    backup = f"{file_path}.backup_{timestamp}"

    try:
        shutil.copy2(file_path, backup)
        print(f"Backup created at: {backup}")
        return True
    except Exception as e:
        print(f"ERROR creating backup: {e}")
        return False

def get_indentation(line):
    """Get the indentation (spaces/tabs) from a line"""
    match = re.match(r'^(\s*)', line)
    return match.group(1) if match else ''

def update_tags(content, new_tags):
    """Update existing tags and add new tags, preserving indentation"""
    lines = content.splitlines()
    existing_tags = {}

    # First pass: find existing tags and their indentation
    for line in lines:
        match = re.search(r'<([^>]+)>', line)
        if match:
            tag_name = match.group(1)
            indentation = get_indentation(line)
            existing_tags[tag_name] = indentation

    # Second pass: update existing tags
    new_lines = []
    for line in lines:
        match = re.search(r'<([^>]+)>', line)
        if match:
            tag_name = match.group(1)

            if tag_name in new_tags:
                # Preserve original indentation
                indentation = get_indentation(line)
                new_lines.append(f"{indentation}{new_tags[tag_name]}")
                continue

        new_lines.append(line)

    # Third pass: add tags that don't exist
    tags_to_add = {k: v for k, v in new_tags.items() if k not in existing_tags}

    if tags_to_add:
        # Find the indentation of the last tag before </root>
        root_closing = None
        last_indentation = '  '  # Default indentation

        for i, line in enumerate(new_lines):
            if '</root>' in line:
                root_closing = i
                break
            match = re.search(r'<([^>]+)>', line)
            if match:
                last_indentation = get_indentation(line)

        # Add tags with the same indentation as other tags
        new_tag_lines = [f"{last_indentation}{v}" for v in tags_to_add.values()]

        if root_closing is not None:
            new_lines = new_lines[:root_closing] + new_tag_lines + new_lines[root_closing:]
        else:
            new_lines.extend(new_tag_lines)

    return '\n'.join(new_lines)

def main():
    print("=" * 60)
    print("X4 Timelines Content Unlocker")
    print("=" * 60)

    # Find userdata.xml
    file_path = find_userdata()
    if not file_path:
        print("\nPress Enter to exit...")
        input()
        return

    print(f"\nFile found: {file_path}")

    # Make backup
    if not make_backup(file_path):
        print("\nPress Enter to exit...")
        input()
        return

    # Read file
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()
    except Exception as e:
        print(f"ERROR reading file: {e}")
        print("\nPress Enter to exit...")
        input()
        return

    # New tags with values (without indentation, it will be added automatically)
    new_tags = {
        'firsttimestartmenu': '<firsttimestartmenu>false</firsttimestartmenu>',
        'timelines_rankings_reset_version': '<timelines_rankings_reset_version>700</timelines_rankings_reset_version>',
        'timelines_rankings_reset_revision': '<timelines_rankings_reset_revision>533594</timelines_rankings_reset_revision>',
        'timelines_player_character_macro': '<timelines_player_character_macro>character_player_timelines_hub_argon_male_macro</timelines_player_character_macro>',
        'timelines_hub_player_isfemale': '<timelines_hub_player_isfemale>0</timelines_hub_player_isfemale>',
        'timelines_scenarios_finished': '<timelines_scenarios_finished>76</timelines_scenarios_finished>',
        'scenario_chapter_1_rating': '<scenario_chapter_1_rating>20</scenario_chapter_1_rating>',
        'scenario_chapter_2_rating': '<scenario_chapter_2_rating>25</scenario_chapter_2_rating>',
        'scenario_chapter_3_rating': '<scenario_chapter_3_rating>30</scenario_chapter_3_rating>',
        'scenario_chapter_4_rating': '<scenario_chapter_4_rating>30</scenario_chapter_4_rating>',
        'scenario_chapter_5_rating': '<scenario_chapter_5_rating>25</scenario_chapter_5_rating>',
        'scenario_chapter_6_rating': '<scenario_chapter_6_rating>30</scenario_chapter_6_rating>',
        'timelines_hub_currenthack': '<timelines_hub_currenthack>5</timelines_hub_currenthack>',
        'hub_a1s2_complete': '<hub_a1s2_complete>0</hub_a1s2_complete>',
        'hub_a1s5_complete': '<hub_a1s5_complete>0</hub_a1s5_complete>',
        'hub_a1s3_complete': '<hub_a1s3_complete>0</hub_a1s3_complete>',
        'hub_playerinventory_interfaceunit': '<hub_playerinventory_interfaceunit>0</hub_playerinventory_interfaceunit>',
        'hub_a1s4_complete': '<hub_a1s4_complete>0</hub_a1s4_complete>',
        'last_scenario_console_group': '<last_scenario_console_group>5</last_scenario_console_group>',
        'hub_a1s6_complete': '<hub_a1s6_complete>0</hub_a1s6_complete>',
        'scenario_race_1_times_finished': '<scenario_race_1_times_finished>1</scenario_race_1_times_finished>',
        'scenario_race_1_last_duration': '<scenario_race_1_last_duration>300.155</scenario_race_1_last_duration>',
        'scenario_race_1_last_score': '<scenario_race_1_last_score>32332.494</scenario_race_1_last_score>',
        'scenario_race_1_last_rating': '<scenario_race_1_last_rating>5</scenario_race_1_last_rating>',
        'scenario_race_1_unlock_notified': '<scenario_race_1_unlock_notified>2</scenario_race_1_unlock_notified>',
        'scenario_race_1_best_score': '<scenario_race_1_best_score>32332.494</scenario_race_1_best_score>',
        'scenario_race_1_best_rating': '<scenario_race_1_best_rating>5</scenario_race_1_best_rating>',
        'scenario_race_1_best_duration': '<scenario_race_1_best_duration>300.155</scenario_race_1_best_duration>',
        'hub_a1s9_complete': '<hub_a1s9_complete>1</hub_a1s9_complete>',
        'scenario_escort_1_times_finished': '<scenario_escort_1_times_finished>2</scenario_escort_1_times_finished>',
        'scenario_escort_1_last_duration': '<scenario_escort_1_last_duration>1037.529</scenario_escort_1_last_duration>',
        'scenario_escort_1_last_score': '<scenario_escort_1_last_score>865</scenario_escort_1_last_score>',
        'scenario_escort_1_last_rating': '<scenario_escort_1_last_rating>5</scenario_escort_1_last_rating>',
        'scenario_escort_1_unlock_notified': '<scenario_escort_1_unlock_notified>3</scenario_escort_1_unlock_notified>',
        'scenario_escort_1_best_score': '<scenario_escort_1_best_score>865</scenario_escort_1_best_score>',
        'scenario_escort_1_best_rating': '<scenario_escort_1_best_rating>5</scenario_escort_1_best_rating>',
        'scenario_escort_1_best_duration': '<scenario_escort_1_best_duration>1037.529</scenario_escort_1_best_duration>',
        'hub_a10s2_complete': '<hub_a10s2_complete>2</hub_a10s2_complete>',
        'scenario_seek_and_destroy_times_finished': '<scenario_seek_and_destroy_times_finished>1</scenario_seek_and_destroy_times_finished>',
        'scenario_seek_and_destroy_last_duration': '<scenario_seek_and_destroy_last_duration>600.01</scenario_seek_and_destroy_last_duration>',
        'scenario_seek_and_destroy_last_score': '<scenario_seek_and_destroy_last_score>739.158</scenario_seek_and_destroy_last_score>',
        'scenario_seek_and_destroy_last_rating': '<scenario_seek_and_destroy_last_rating>5</scenario_seek_and_destroy_last_rating>',
        'scenario_seek_and_destroy_unlock_notified': '<scenario_seek_and_destroy_unlock_notified>1</scenario_seek_and_destroy_unlock_notified>',
        'scenario_seek_and_destroy_best_score': '<scenario_seek_and_destroy_best_score>739.158</scenario_seek_and_destroy_best_score>',
        'scenario_seek_and_destroy_best_rating': '<scenario_seek_and_destroy_best_rating>5</scenario_seek_and_destroy_best_rating>',
        'scenario_seek_and_destroy_best_duration': '<scenario_seek_and_destroy_best_duration>600.01</scenario_seek_and_destroy_best_duration>',
        'scenario_chapter_1_completed': '<scenario_chapter_1_completed>1</scenario_chapter_1_completed>',
        'hub_a8s7_complete': '<hub_a8s7_complete>3</hub_a8s7_complete>',
        'hub_a8s8_complete': '<hub_a8s8_complete>3</hub_a8s8_complete>',
        'hub_a8s9_complete': '<hub_a8s9_complete>3</hub_a8s9_complete>',
        'scenario_tharkas_cascade_times_finished': '<scenario_tharkas_cascade_times_finished>2</scenario_tharkas_cascade_times_finished>',
        'scenario_tharkas_cascade_last_duration': '<scenario_tharkas_cascade_last_duration>415.614</scenario_tharkas_cascade_last_duration>',
        'scenario_tharkas_cascade_last_score': '<scenario_tharkas_cascade_last_score>2097.241</scenario_tharkas_cascade_last_score>',
        'scenario_tharkas_cascade_last_rating': '<scenario_tharkas_cascade_last_rating>5</scenario_tharkas_cascade_last_rating>',
        'scenario_tharkas_cascade_unlock_notified': '<scenario_tharkas_cascade_unlock_notified>2</scenario_tharkas_cascade_unlock_notified>',
        'scenario_tharkas_cascade_best_score': '<scenario_tharkas_cascade_best_score>2097.241</scenario_tharkas_cascade_best_score>',
        'scenario_tharkas_cascade_best_rating': '<scenario_tharkas_cascade_best_rating>5</scenario_tharkas_cascade_best_rating>',
        'scenario_tharkas_cascade_best_duration': '<scenario_tharkas_cascade_best_duration>415.614</scenario_tharkas_cascade_best_duration>',
        'scenario_chapter_1_terminus_completed': '<scenario_chapter_1_terminus_completed>1</scenario_chapter_1_terminus_completed>',
        'hub_a2s1_complete': '<hub_a2s1_complete>6</hub_a2s1_complete>',
        'hub_a2s2_complete': '<hub_a2s2_complete>6</hub_a2s2_complete>',
        'hub_a4s3_complete': '<hub_a4s3_complete>6</hub_a4s3_complete>',
        'hub_a4s2_complete': '<hub_a4s2_complete>6</hub_a4s2_complete>',
        'scenario_race_2_times_finished': '<scenario_race_2_times_finished>1</scenario_race_2_times_finished>',
        'scenario_race_2_last_duration': '<scenario_race_2_last_duration>181.128</scenario_race_2_last_duration>',
        'scenario_race_2_last_score': '<scenario_race_2_last_score>30333.588</scenario_race_2_last_score>',
        'scenario_race_2_last_rating': '<scenario_race_2_last_rating>5</scenario_race_2_last_rating>',
        'scenario_race_2_unlock_notified': '<scenario_race_2_unlock_notified>2</scenario_race_2_unlock_notified>',
        'scenario_race_2_best_score': '<scenario_race_2_best_score>30333.588</scenario_race_2_best_score>',
        'scenario_race_2_best_rating': '<scenario_race_2_best_rating>5</scenario_race_2_best_rating>',
        'scenario_race_2_best_duration': '<scenario_race_2_best_duration>181.128</scenario_race_2_best_duration>',
        'hub_a2s3_complete': '<hub_a2s3_complete>7</hub_a2s3_complete>',
        'hub_a4s7_complete': '<hub_a4s7_complete>7</hub_a4s7_complete>',
        'timelines_hub_hack_ch2_scenario_waveattack_1': '<timelines_hub_hack_ch2_scenario_waveattack_1>1</timelines_hub_hack_ch2_scenario_waveattack_1>',
        'hub_a8s1_complete': '<hub_a8s1_complete>7</hub_a8s1_complete>',
        'scenario_waveattack_1_times_finished': '<scenario_waveattack_1_times_finished>1</scenario_waveattack_1_times_finished>',
        'scenario_waveattack_1_last_duration': '<scenario_waveattack_1_last_duration>1052.26</scenario_waveattack_1_last_duration>',
        'scenario_waveattack_1_last_score': '<scenario_waveattack_1_last_score>686</scenario_waveattack_1_last_score>',
        'scenario_waveattack_1_last_rating': '<scenario_waveattack_1_last_rating>5</scenario_waveattack_1_last_rating>',
        'scenario_waveattack_1_unlock_notified': '<scenario_waveattack_1_unlock_notified>1</scenario_waveattack_1_unlock_notified>',
        'scenario_waveattack_1_best_score': '<scenario_waveattack_1_best_score>686</scenario_waveattack_1_best_score>',
        'scenario_waveattack_1_best_rating': '<scenario_waveattack_1_best_rating>5</scenario_waveattack_1_best_rating>',
        'scenario_waveattack_1_best_duration': '<scenario_waveattack_1_best_duration>1052.26</scenario_waveattack_1_best_duration>',
        'hub_a2s4_complete': '<hub_a2s4_complete>8</hub_a2s4_complete>',
        'hub_a3s5_complete': '<hub_a3s5_complete>8</hub_a3s5_complete>',
        'hub_a2s5_complete': '<hub_a2s5_complete>8</hub_a2s5_complete>',
        'hub_a3s6_complete': '<hub_a3s6_complete>8</hub_a3s6_complete>',
        'scenario_mining_2_times_finished': '<scenario_mining_2_times_finished>4</scenario_mining_2_times_finished>',
        'scenario_mining_2_last_duration': '<scenario_mining_2_last_duration>307.511</scenario_mining_2_last_duration>',
        'scenario_mining_2_last_score': '<scenario_mining_2_last_score>1594</scenario_mining_2_last_score>',
        'scenario_mining_2_last_rating': '<scenario_mining_2_last_rating>5</scenario_mining_2_last_rating>',
        'scenario_mining_2_unlock_notified': '<scenario_mining_2_unlock_notified>4</scenario_mining_2_unlock_notified>',
        'scenario_mining_2_best_score': '<scenario_mining_2_best_score>1594</scenario_mining_2_best_score>',
        'scenario_mining_2_best_rating': '<scenario_mining_2_best_rating>5</scenario_mining_2_best_rating>',
        'scenario_mining_2_best_duration': '<scenario_mining_2_best_duration>307.511</scenario_mining_2_best_duration>',
        'hub_a3s7_complete': '<hub_a3s7_complete>12</hub_a3s7_complete>',
        'hub_a3s11_complete': '<hub_a3s11_complete>12</hub_a3s11_complete>',
        'scenario_spacesuit_1_times_finished': '<scenario_spacesuit_1_times_finished>11</scenario_spacesuit_1_times_finished>',
        'scenario_spacesuit_1_last_duration': '<scenario_spacesuit_1_last_duration>35.388</scenario_spacesuit_1_last_duration>',
        'scenario_spacesuit_1_last_score': '<scenario_spacesuit_1_last_score>15339.325</scenario_spacesuit_1_last_score>',
        'scenario_spacesuit_1_last_rating': '<scenario_spacesuit_1_last_rating>5</scenario_spacesuit_1_last_rating>',
        'scenario_spacesuit_1_unlock_notified': '<scenario_spacesuit_1_unlock_notified>11</scenario_spacesuit_1_unlock_notified>',
        'scenario_spacesuit_1_best_score': '<scenario_spacesuit_1_best_score>15339.325</scenario_spacesuit_1_best_score>',
        'scenario_spacesuit_1_best_rating': '<scenario_spacesuit_1_best_rating>5</scenario_spacesuit_1_best_rating>',
        'scenario_spacesuit_1_best_duration': '<scenario_spacesuit_1_best_duration>35.388</scenario_spacesuit_1_best_duration>',
        'scenario_chapter_2_completed': '<scenario_chapter_2_completed>1</scenario_chapter_2_completed>',
        'hub_a4s12_complete': '<hub_a4s12_complete>23</hub_a4s12_complete>',
        'scenario_waveattack_antigone_times_finished': '<scenario_waveattack_antigone_times_finished>1</scenario_waveattack_antigone_times_finished>',
        'scenario_waveattack_antigone_last_duration': '<scenario_waveattack_antigone_last_duration>1145.789</scenario_waveattack_antigone_last_duration>',
        'scenario_waveattack_antigone_last_score': '<scenario_waveattack_antigone_last_score>715</scenario_waveattack_antigone_last_score>',
        'scenario_waveattack_antigone_last_rating': '<scenario_waveattack_antigone_last_rating>5</scenario_waveattack_antigone_last_rating>',
        'scenario_waveattack_antigone_unlock_notified': '<scenario_waveattack_antigone_unlock_notified>2</scenario_waveattack_antigone_unlock_notified>',
        'scenario_waveattack_antigone_best_score': '<scenario_waveattack_antigone_best_score>715</scenario_waveattack_antigone_best_score>',
        'scenario_waveattack_antigone_best_rating': '<scenario_waveattack_antigone_best_rating>5</scenario_waveattack_antigone_best_rating>',
        'scenario_waveattack_antigone_best_duration': '<scenario_waveattack_antigone_best_duration>1145.789</scenario_waveattack_antigone_best_duration>',
        'scenario_chapter_2_terminus_completed': '<scenario_chapter_2_terminus_completed>1</scenario_chapter_2_terminus_completed>',
        'hub_a3s1_complete': '<hub_a3s1_complete>24</hub_a3s1_complete>',
        'hub_a3s2_complete': '<hub_a3s2_complete>25</hub_a3s2_complete>',
        'scenario_recruitment_1_times_finished': '<scenario_recruitment_1_times_finished>4</scenario_recruitment_1_times_finished>',
        'scenario_recruitment_1_last_duration': '<scenario_recruitment_1_last_duration>53.602</scenario_recruitment_1_last_duration>',
        'scenario_recruitment_1_last_score': '<scenario_recruitment_1_last_score>5</scenario_recruitment_1_last_score>',
        'scenario_recruitment_1_last_rating': '<scenario_recruitment_1_last_rating>5</scenario_recruitment_1_last_rating>',
        'scenario_recruitment_1_unlock_notified': '<scenario_recruitment_1_unlock_notified>4</scenario_recruitment_1_unlock_notified>',
        'scenario_recruitment_1_best_score': '<scenario_recruitment_1_best_score>5</scenario_recruitment_1_best_score>',
        'scenario_recruitment_1_best_rating': '<scenario_recruitment_1_best_rating>5</scenario_recruitment_1_best_rating>',
        'scenario_recruitment_1_best_duration': '<scenario_recruitment_1_best_duration>53.602</scenario_recruitment_1_best_duration>',
        'hub_a3s3_complete': '<hub_a3s3_complete>28</hub_a3s3_complete>',
        'hub_a4s4_complete': '<hub_a4s4_complete>28</hub_a4s4_complete>',
        'scenario_race_3_times_finished': '<scenario_race_3_times_finished>1</scenario_race_3_times_finished>',
        'scenario_race_3_last_duration': '<scenario_race_3_last_duration>141.823</scenario_race_3_last_duration>',
        'scenario_race_3_last_score': '<scenario_race_3_last_score>35118.352</scenario_race_3_last_score>',
        'scenario_race_3_last_rating': '<scenario_race_3_last_rating>5</scenario_race_3_last_rating>',
        'scenario_race_3_unlock_notified': '<scenario_race_3_unlock_notified>2</scenario_race_3_unlock_notified>',
        'scenario_race_3_best_score': '<scenario_race_3_best_score>35118.352</scenario_race_3_best_score>',
        'scenario_race_3_best_rating': '<scenario_race_3_best_rating>5</scenario_race_3_best_rating>',
        'scenario_race_3_best_duration': '<scenario_race_3_best_duration>141.823</scenario_race_3_best_duration>',
        'hub_a3s4_complete': '<hub_a3s4_complete>29</hub_a3s4_complete>',
        'hub_a4s5_complete': '<hub_a4s5_complete>29</hub_a4s5_complete>',
        'hub_a10s5_complete': '<hub_a10s5_complete>29</hub_a10s5_complete>',
        'hub_a10s7_complete': '<hub_a10s7_complete>29</hub_a10s7_complete>',
        'hub_a10s8_complete': '<hub_a10s8_complete>29</hub_a10s8_complete>',
        'hub_a10s6_complete': '<hub_a10s6_complete>29</hub_a10s6_complete>',
        'timelines_hub_hack_ch3_scenario_mining_4': '<timelines_hub_hack_ch3_scenario_mining_4>1</timelines_hub_hack_ch3_scenario_mining_4>',
        'hub_a8s2_complete': '<hub_a8s2_complete>29</hub_a8s2_complete>',
        'scenario_mining_4_times_finished': '<scenario_mining_4_times_finished>1</scenario_mining_4_times_finished>',
        'scenario_mining_4_last_duration': '<scenario_mining_4_last_duration>604.016</scenario_mining_4_last_duration>',
        'scenario_mining_4_last_score': '<scenario_mining_4_last_score>6251</scenario_mining_4_last_score>',
        'scenario_mining_4_last_rating': '<scenario_mining_4_last_rating>5</scenario_mining_4_last_rating>',
        'scenario_mining_4_unlock_notified': '<scenario_mining_4_unlock_notified>1</scenario_mining_4_unlock_notified>',
        'scenario_mining_4_best_score': '<scenario_mining_4_best_score>6251</scenario_mining_4_best_score>',
        'scenario_mining_4_best_rating': '<scenario_mining_4_best_rating>5</scenario_mining_4_best_rating>',
        'scenario_mining_4_best_duration': '<scenario_mining_4_best_duration>604.016</scenario_mining_4_best_duration>',
        'hub_a3s8_complete': '<hub_a3s8_complete>30</hub_a3s8_complete>',
        'hub_a5s1_complete': '<hub_a5s1_complete>30</hub_a5s1_complete>',
        'scenario_assassinate_times_finished': '<scenario_assassinate_times_finished>4</scenario_assassinate_times_finished>',
        'scenario_assassinate_last_duration': '<scenario_assassinate_last_duration>258.312</scenario_assassinate_last_duration>',
        'scenario_assassinate_last_score': '<scenario_assassinate_last_score>2145.679</scenario_assassinate_last_score>',
        'scenario_assassinate_last_rating': '<scenario_assassinate_last_rating>5</scenario_assassinate_last_rating>',
        'scenario_assassinate_unlock_notified': '<scenario_assassinate_unlock_notified>4</scenario_assassinate_unlock_notified>',
        'scenario_assassinate_best_score': '<scenario_assassinate_best_score>2145.679</scenario_assassinate_best_score>',
        'scenario_assassinate_best_rating': '<scenario_assassinate_best_rating>5</scenario_assassinate_best_rating>',
        'scenario_assassinate_best_duration': '<scenario_assassinate_best_duration>258.312</scenario_assassinate_best_duration>',
        'hub_a3s9_complete': '<hub_a3s9_complete>34</hub_a3s9_complete>',
        'fleetbattle1_argon': '<fleetbattle1_argon>1</fleetbattle1_argon>',
        'scenario_fleet_battle_1_times_finished': '<scenario_fleet_battle_1_times_finished>1</scenario_fleet_battle_1_times_finished>',
        'scenario_fleet_battle_1_last_duration': '<scenario_fleet_battle_1_last_duration>637.209</scenario_fleet_battle_1_last_duration>',
        'scenario_fleet_battle_1_last_score': '<scenario_fleet_battle_1_last_score>1118</scenario_fleet_battle_1_last_score>',
        'scenario_fleet_battle_1_last_rating': '<scenario_fleet_battle_1_last_rating>5</scenario_fleet_battle_1_last_rating>',
        'scenario_fleet_battle_1_unlock_notified': '<scenario_fleet_battle_1_unlock_notified>1</scenario_fleet_battle_1_unlock_notified>',
        'scenario_fleet_battle_1_best_score': '<scenario_fleet_battle_1_best_score>1118</scenario_fleet_battle_1_best_score>',
        'scenario_fleet_battle_1_best_rating': '<scenario_fleet_battle_1_best_rating>5</scenario_fleet_battle_1_best_rating>',
        'scenario_fleet_battle_1_best_duration': '<scenario_fleet_battle_1_best_duration>637.209</scenario_fleet_battle_1_best_duration>',
        'scenario_chapter_3_completed': '<scenario_chapter_3_completed>1</scenario_chapter_3_completed>',
        'hub_a3s10_complete': '<hub_a3s10_complete>35</hub_a3s10_complete>',
        'hub_a3s12_complete': '<hub_a3s12_complete>35</hub_a3s12_complete>',
        'hub_a3s13_complete': '<hub_a3s13_complete>35</hub_a3s13_complete>',
        'hub_a4s8_complete': '<hub_a4s8_complete>35</hub_a4s8_complete>',
        'scenario_m0_boss_battle_times_finished': '<scenario_m0_boss_battle_times_finished>2</scenario_m0_boss_battle_times_finished>',
        'scenario_m0_boss_battle_last_duration': '<scenario_m0_boss_battle_last_duration>1090.594</scenario_m0_boss_battle_last_duration>',
        'scenario_m0_boss_battle_last_score': '<scenario_m0_boss_battle_last_score>1720</scenario_m0_boss_battle_last_score>',
        'scenario_m0_boss_battle_last_rating': '<scenario_m0_boss_battle_last_rating>5</scenario_m0_boss_battle_last_rating>',
        'scenario_m0_boss_battle_unlock_notified': '<scenario_m0_boss_battle_unlock_notified>2</scenario_m0_boss_battle_unlock_notified>',
        'scenario_m0_boss_battle_best_score': '<scenario_m0_boss_battle_best_score>1720</scenario_m0_boss_battle_best_score>',
        'scenario_m0_boss_battle_best_rating': '<scenario_m0_boss_battle_best_rating>5</scenario_m0_boss_battle_best_rating>',
        'scenario_m0_boss_battle_best_duration': '<scenario_m0_boss_battle_best_duration>1090.594</scenario_m0_boss_battle_best_duration>',
        'scenario_chapter_3_terminus_completed': '<scenario_chapter_3_terminus_completed>1</scenario_chapter_3_terminus_completed>',
        'hub_a4s1_complete': '<hub_a4s1_complete>37</hub_a4s1_complete>',
        'scenario_mining_1_times_finished': '<scenario_mining_1_times_finished>2</scenario_mining_1_times_finished>',
        'scenario_mining_1_last_duration': '<scenario_mining_1_last_duration>65.4927</scenario_mining_1_last_duration>',
        'scenario_mining_1_last_score': '<scenario_mining_1_last_score>101</scenario_mining_1_last_score>',
        'scenario_mining_1_last_rating': '<scenario_mining_1_last_rating>5</scenario_mining_1_last_rating>',
        'scenario_mining_1_unlock_notified': '<scenario_mining_1_unlock_notified>2</scenario_mining_1_unlock_notified>',
        'scenario_mining_1_best_score': '<scenario_mining_1_best_score>101</scenario_mining_1_best_score>',
        'scenario_mining_1_best_rating': '<scenario_mining_1_best_rating>5</scenario_mining_1_best_rating>',
        'scenario_mining_1_best_duration': '<scenario_mining_1_best_duration>65.4927</scenario_mining_1_best_duration>',
        'hub_a4s6_complete': '<hub_a4s6_complete>39</hub_a4s6_complete>',
        'timelines_hub_hack_ch4_scenario_trading_1': '<timelines_hub_hack_ch4_scenario_trading_1>1</timelines_hub_hack_ch4_scenario_trading_1>',
        'hub_a8s3_complete': '<hub_a8s3_complete>39</hub_a8s3_complete>',
        'scenario_trading_1_times_finished': '<scenario_trading_1_times_finished>1</scenario_trading_1_times_finished>',
        'scenario_trading_1_last_duration': '<scenario_trading_1_last_duration>542.187</scenario_trading_1_last_duration>',
        'scenario_trading_1_last_score': '<scenario_trading_1_last_score>1858.54</scenario_trading_1_last_score>',
        'scenario_trading_1_last_rating': '<scenario_trading_1_last_rating>5</scenario_trading_1_last_rating>',
        'scenario_trading_1_unlock_notified': '<scenario_trading_1_unlock_notified>1</scenario_trading_1_unlock_notified>',
        'scenario_trading_1_best_score': '<scenario_trading_1_best_score>1858.54</scenario_trading_1_best_score>',
        'scenario_trading_1_best_rating': '<scenario_trading_1_best_rating>5</scenario_trading_1_best_rating>',
        'scenario_trading_1_best_duration': '<scenario_trading_1_best_duration>542.187</scenario_trading_1_best_duration>',
        'hub_a4s9_complete': '<hub_a4s9_complete>40</hub_a4s9_complete>',
        'scenario_spacesuit_2_times_finished': '<scenario_spacesuit_2_times_finished>8</scenario_spacesuit_2_times_finished>',
        'scenario_spacesuit_2_last_duration': '<scenario_spacesuit_2_last_duration>308.441</scenario_spacesuit_2_last_duration>',
        'scenario_spacesuit_2_last_score': '<scenario_spacesuit_2_last_score>3300</scenario_spacesuit_2_last_score>',
        'scenario_spacesuit_2_last_rating': '<scenario_spacesuit_2_last_rating>4</scenario_spacesuit_2_last_rating>',
        'scenario_spacesuit_2_unlock_notified': '<scenario_spacesuit_2_unlock_notified>8</scenario_spacesuit_2_unlock_notified>',
        'scenario_spacesuit_2_best_score': '<scenario_spacesuit_2_best_score>3500</scenario_spacesuit_2_best_score>',
        'scenario_spacesuit_2_best_rating': '<scenario_spacesuit_2_best_rating>5</scenario_spacesuit_2_best_rating>',
        'scenario_spacesuit_2_best_duration': '<scenario_spacesuit_2_best_duration>310.36</scenario_spacesuit_2_best_duration>',
        'hub_a4s10_complete': '<hub_a4s10_complete>42</hub_a4s10_complete>',
        'hub_a5s3_complete': '<hub_a5s3_complete>42</hub_a5s3_complete>',
        'hub_a9s1_complete': '<hub_a9s1_complete>42</hub_a9s1_complete>',
        'hub_playerinventory_cosmeticskit': '<hub_playerinventory_cosmeticskit>0</hub_playerinventory_cosmeticskit>',
        'hub_playerinventory_fieldarray': '<hub_playerinventory_fieldarray>0</hub_playerinventory_fieldarray>',
        'hub_a9s2_complete': '<hub_a9s2_complete>42</hub_a9s2_complete>',
        'hub_a9s3_complete': '<hub_a9s3_complete>42</hub_a9s3_complete>',
        'scenario_weaken_station_times_finished': '<scenario_weaken_station_times_finished>1</scenario_weaken_station_times_finished>',
        'scenario_weaken_station_last_duration': '<scenario_weaken_station_last_duration>228.893</scenario_weaken_station_last_duration>',
        'scenario_weaken_station_last_score': '<scenario_weaken_station_last_score>2013.172</scenario_weaken_station_last_score>',
        'scenario_weaken_station_last_rating': '<scenario_weaken_station_last_rating>5</scenario_weaken_station_last_rating>',
        'scenario_weaken_station_unlock_notified': '<scenario_weaken_station_unlock_notified>1</scenario_weaken_station_unlock_notified>',
        'scenario_weaken_station_best_score': '<scenario_weaken_station_best_score>2013.172</scenario_weaken_station_best_score>',
        'scenario_weaken_station_best_rating': '<scenario_weaken_station_best_rating>5</scenario_weaken_station_best_rating>',
        'scenario_weaken_station_best_duration': '<scenario_weaken_station_best_duration>228.893</scenario_weaken_station_best_duration>',
        'scenario_weaken_fleet_times_finished': '<scenario_weaken_fleet_times_finished>1</scenario_weaken_fleet_times_finished>',
        'scenario_weaken_fleet_last_duration': '<scenario_weaken_fleet_last_duration>180.971</scenario_weaken_fleet_last_duration>',
        'scenario_weaken_fleet_last_score': '<scenario_weaken_fleet_last_score>1069.783</scenario_weaken_fleet_last_score>',
        'scenario_weaken_fleet_last_rating': '<scenario_weaken_fleet_last_rating>5</scenario_weaken_fleet_last_rating>',
        'scenario_weaken_fleet_unlock_notified': '<scenario_weaken_fleet_unlock_notified>1</scenario_weaken_fleet_unlock_notified>',
        'scenario_weaken_fleet_best_score': '<scenario_weaken_fleet_best_score>1069.783</scenario_weaken_fleet_best_score>',
        'scenario_weaken_fleet_best_rating': '<scenario_weaken_fleet_best_rating>5</scenario_weaken_fleet_best_rating>',
        'scenario_weaken_fleet_best_duration': '<scenario_weaken_fleet_best_duration>180.971</scenario_weaken_fleet_best_duration>',
        'scenario_chapter_4_completed': '<scenario_chapter_4_completed>1</scenario_chapter_4_completed>',
        'timelines_presidents_end_blackbox': '<timelines_presidents_end_blackbox>1</timelines_presidents_end_blackbox>',
        'timelines_presidents_end_transmit': '<timelines_presidents_end_transmit>1</timelines_presidents_end_transmit>',
        'scenario_presidents_end_1_times_finished': '<scenario_presidents_end_1_times_finished>1</scenario_presidents_end_1_times_finished>',
        'scenario_presidents_end_1_last_duration': '<scenario_presidents_end_1_last_duration>1093.557</scenario_presidents_end_1_last_duration>',
        'scenario_presidents_end_1_last_score': '<scenario_presidents_end_1_last_score>443</scenario_presidents_end_1_last_score>',
        'scenario_presidents_end_1_last_rating': '<scenario_presidents_end_1_last_rating>5</scenario_presidents_end_1_last_rating>',
        'scenario_presidents_end_1_unlock_notified': '<scenario_presidents_end_1_unlock_notified>1</scenario_presidents_end_1_unlock_notified>',
        'scenario_presidents_end_1_best_score': '<scenario_presidents_end_1_best_score>443</scenario_presidents_end_1_best_score>',
        'scenario_presidents_end_1_best_rating': '<scenario_presidents_end_1_best_rating>5</scenario_presidents_end_1_best_rating>',
        'scenario_presidents_end_1_best_duration': '<scenario_presidents_end_1_best_duration>1093.557</scenario_presidents_end_1_best_duration>',
        'scenario_chapter_4_terminus_completed': '<scenario_chapter_4_terminus_completed>1</scenario_chapter_4_terminus_completed>',
        'scenario_mining_3_times_finished': '<scenario_mining_3_times_finished>1</scenario_mining_3_times_finished>',
        'scenario_mining_3_last_duration': '<scenario_mining_3_last_duration>935.697</scenario_mining_3_last_duration>',
        'scenario_mining_3_last_score': '<scenario_mining_3_last_score>6270</scenario_mining_3_last_score>',
        'scenario_mining_3_last_rating': '<scenario_mining_3_last_rating>5</scenario_mining_3_last_rating>',
        'scenario_mining_3_unlock_notified': '<scenario_mining_3_unlock_notified>1</scenario_mining_3_unlock_notified>',
        'scenario_mining_3_best_score': '<scenario_mining_3_best_score>6270</scenario_mining_3_best_score>',
        'scenario_mining_3_best_rating': '<scenario_mining_3_best_rating>5</scenario_mining_3_best_rating>',
        'scenario_mining_3_best_duration': '<scenario_mining_3_best_duration>935.697</scenario_mining_3_best_duration>',
        'scenario_trading_2_times_finished': '<scenario_trading_2_times_finished>2</scenario_trading_2_times_finished>',
        'scenario_trading_2_last_duration': '<scenario_trading_2_last_duration>1096.252</scenario_trading_2_last_duration>',
        'scenario_trading_2_last_score': '<scenario_trading_2_last_score>3829</scenario_trading_2_last_score>',
        'scenario_trading_2_last_rating': '<scenario_trading_2_last_rating>5</scenario_trading_2_last_rating>',
        'scenario_trading_2_unlock_notified': '<scenario_trading_2_unlock_notified>2</scenario_trading_2_unlock_notified>',
        'scenario_trading_2_best_score': '<scenario_trading_2_best_score>3829</scenario_trading_2_best_score>',
        'scenario_trading_2_best_rating': '<scenario_trading_2_best_rating>5</scenario_trading_2_best_rating>',
        'scenario_trading_2_best_duration': '<scenario_trading_2_best_duration>1096.252</scenario_trading_2_best_duration>',
        'scenario_spacesuit_3_times_finished': '<scenario_spacesuit_3_times_finished>5</scenario_spacesuit_3_times_finished>',
        'scenario_spacesuit_3_last_duration': '<scenario_spacesuit_3_last_duration>123.413</scenario_spacesuit_3_last_duration>',
        'scenario_spacesuit_3_last_score': '<scenario_spacesuit_3_last_score>6106.963</scenario_spacesuit_3_last_score>',
        'scenario_spacesuit_3_last_rating': '<scenario_spacesuit_3_last_rating>5</scenario_spacesuit_3_last_rating>',
        'scenario_spacesuit_3_unlock_notified': '<scenario_spacesuit_3_unlock_notified>5</scenario_spacesuit_3_unlock_notified>',
        'scenario_spacesuit_3_best_score': '<scenario_spacesuit_3_best_score>6106.963</scenario_spacesuit_3_best_score>',
        'scenario_spacesuit_3_best_rating': '<scenario_spacesuit_3_best_rating>5</scenario_spacesuit_3_best_rating>',
        'scenario_spacesuit_3_best_duration': '<scenario_spacesuit_3_best_duration>123.413</scenario_spacesuit_3_best_duration>',
        'scenario_disable_capship_times_finished': '<scenario_disable_capship_times_finished>1</scenario_disable_capship_times_finished>',
        'scenario_disable_capship_last_duration': '<scenario_disable_capship_last_duration>189.961</scenario_disable_capship_last_duration>',
        'scenario_disable_capship_last_score': '<scenario_disable_capship_last_score>1589.794</scenario_disable_capship_last_score>',
        'scenario_disable_capship_last_rating': '<scenario_disable_capship_last_rating>5</scenario_disable_capship_last_rating>',
        'scenario_disable_capship_unlock_notified': '<scenario_disable_capship_unlock_notified>1</scenario_disable_capship_unlock_notified>',
        'scenario_disable_capship_best_score': '<scenario_disable_capship_best_score>1589.794</scenario_disable_capship_best_score>',
        'scenario_disable_capship_best_rating': '<scenario_disable_capship_best_rating>5</scenario_disable_capship_best_rating>',
        'scenario_disable_capship_best_duration': '<scenario_disable_capship_best_duration>189.961</scenario_disable_capship_best_duration>',
        'scenario_chapter_5_completed': '<scenario_chapter_5_completed>1</scenario_chapter_5_completed>',
        'scenario_khaak_boss_battle_times_finished': '<scenario_khaak_boss_battle_times_finished>3</scenario_khaak_boss_battle_times_finished>',
        'scenario_khaak_boss_battle_last_duration': '<scenario_khaak_boss_battle_last_duration>437.465</scenario_khaak_boss_battle_last_duration>',
        'scenario_khaak_boss_battle_last_score': '<scenario_khaak_boss_battle_last_score>1042.838</scenario_khaak_boss_battle_last_score>',
        'scenario_khaak_boss_battle_last_rating': '<scenario_khaak_boss_battle_last_rating>5</scenario_khaak_boss_battle_last_rating>',
        'scenario_khaak_boss_battle_unlock_notified': '<scenario_khaak_boss_battle_unlock_notified>3</scenario_khaak_boss_battle_unlock_notified>',
        'scenario_khaak_boss_battle_best_score': '<scenario_khaak_boss_battle_best_score>1042.838</scenario_khaak_boss_battle_best_score>',
        'scenario_khaak_boss_battle_best_rating': '<scenario_khaak_boss_battle_best_rating>5</scenario_khaak_boss_battle_best_rating>',
        'scenario_khaak_boss_battle_best_duration': '<scenario_khaak_boss_battle_best_duration>437.465</scenario_khaak_boss_battle_best_duration>',
        'scenario_chapter_5_terminus_completed': '<scenario_chapter_5_terminus_completed>1</scenario_chapter_5_terminus_completed>',
        'scenario_trading_3_times_finished': '<scenario_trading_3_times_finished>1</scenario_trading_3_times_finished>',
        'scenario_trading_3_last_duration': '<scenario_trading_3_last_duration>507.276</scenario_trading_3_last_duration>',
        'scenario_trading_3_last_score': '<scenario_trading_3_last_score>2198.63</scenario_trading_3_last_score>',
        'scenario_trading_3_last_rating': '<scenario_trading_3_last_rating>5</scenario_trading_3_last_rating>',
        'scenario_trading_3_unlock_notified': '<scenario_trading_3_unlock_notified>1</scenario_trading_3_unlock_notified>',
        'scenario_trading_3_best_score': '<scenario_trading_3_best_score>2198.63</scenario_trading_3_best_score>',
        'scenario_trading_3_best_rating': '<scenario_trading_3_best_rating>5</scenario_trading_3_best_rating>',
        'scenario_trading_3_best_duration': '<scenario_trading_3_best_duration>507.276</scenario_trading_3_best_duration>',
        'scenario_mining_7_times_finished': '<scenario_mining_7_times_finished>1</scenario_mining_7_times_finished>',
        'scenario_mining_7_last_duration': '<scenario_mining_7_last_duration>3383.07</scenario_mining_7_last_duration>',
        'scenario_mining_7_last_score': '<scenario_mining_7_last_score>8372</scenario_mining_7_last_score>',
        'scenario_mining_7_last_rating': '<scenario_mining_7_last_rating>5</scenario_mining_7_last_rating>',
        'scenario_mining_7_unlock_notified': '<scenario_mining_7_unlock_notified>1</scenario_mining_7_unlock_notified>',
        'scenario_mining_7_best_score': '<scenario_mining_7_best_score>8372</scenario_mining_7_best_score>',
        'scenario_mining_7_best_rating': '<scenario_mining_7_best_rating>5</scenario_mining_7_best_rating>',
        'scenario_mining_7_best_duration': '<scenario_mining_7_best_duration>3383.07</scenario_mining_7_best_duration>',
        'scenario_protect_object_times_finished': '<scenario_protect_object_times_finished>2</scenario_protect_object_times_finished>',
        'scenario_protect_object_last_duration': '<scenario_protect_object_last_duration>1370.711</scenario_protect_object_last_duration>',
        'scenario_protect_object_last_score': '<scenario_protect_object_last_score>217.922</scenario_protect_object_last_score>',
        'scenario_protect_object_last_rating': '<scenario_protect_object_last_rating>5</scenario_protect_object_last_rating>',
        'scenario_protect_object_unlock_notified': '<scenario_protect_object_unlock_notified>2</scenario_protect_object_unlock_notified>',
        'scenario_protect_object_best_score': '<scenario_protect_object_best_score>217.922</scenario_protect_object_best_score>',
        'scenario_protect_object_best_rating': '<scenario_protect_object_best_rating>5</scenario_protect_object_best_rating>',
        'scenario_protect_object_best_duration': '<scenario_protect_object_best_duration>1370.711</scenario_protect_object_best_duration>',
        'scenario_fleet_battle_2_times_finished': '<scenario_fleet_battle_2_times_finished>1</scenario_fleet_battle_2_times_finished>',
        'scenario_fleet_battle_2_last_duration': '<scenario_fleet_battle_2_last_duration>1148.215</scenario_fleet_battle_2_last_duration>',
        'scenario_fleet_battle_2_last_score': '<scenario_fleet_battle_2_last_score>5548.92</scenario_fleet_battle_2_last_score>',
        'scenario_fleet_battle_2_last_rating': '<scenario_fleet_battle_2_last_rating>5</scenario_fleet_battle_2_last_rating>',
        'scenario_fleet_battle_2_unlock_notified': '<scenario_fleet_battle_2_unlock_notified>1</scenario_fleet_battle_2_unlock_notified>',
        'scenario_fleet_battle_2_best_score': '<scenario_fleet_battle_2_best_score>5548.92</scenario_fleet_battle_2_best_score>',
        'scenario_fleet_battle_2_best_rating': '<scenario_fleet_battle_2_best_rating>5</scenario_fleet_battle_2_best_rating>',
        'scenario_fleet_battle_2_best_duration': '<scenario_fleet_battle_2_best_duration>1148.215</scenario_fleet_battle_2_best_duration>',
        'scenario_spacesuit_4_times_finished': '<scenario_spacesuit_4_times_finished>7</scenario_spacesuit_4_times_finished>',
        'scenario_spacesuit_4_last_duration': '<scenario_spacesuit_4_last_duration>275.121</scenario_spacesuit_4_last_duration>',
        'scenario_spacesuit_4_last_score': '<scenario_spacesuit_4_last_score>2000.234</scenario_spacesuit_4_last_score>',
        'scenario_spacesuit_4_last_rating': '<scenario_spacesuit_4_last_rating>5</scenario_spacesuit_4_last_rating>',
        'scenario_spacesuit_4_best_score': '<scenario_spacesuit_4_best_score>2000.234</scenario_spacesuit_4_best_score>',
        'scenario_spacesuit_4_best_rating': '<scenario_spacesuit_4_best_rating>5</scenario_spacesuit_4_best_rating>',
        'scenario_spacesuit_4_best_duration': '<scenario_spacesuit_4_best_duration>255.121</scenario_spacesuit_4_best_duration>',
        'scenario_chapter_6_completed': '<scenario_chapter_6_completed>1</scenario_chapter_6_completed>',
        'scenario_spacesuit_4_unlock_notified': '<scenario_spacesuit_4_unlock_notified>5</scenario_spacesuit_4_unlock_notified>',
        'timelines_hub_hack_ch6_scenario_dragonfyre': '<timelines_hub_hack_ch6_scenario_dragonfyre>1</timelines_hub_hack_ch6_scenario_dragonfyre>',
        'hub_a5s4_complete': '<hub_a5s4_complete>75</hub_a5s4_complete>',
        'scenario_dragonfyre_times_finished': '<scenario_dragonfyre_times_finished>1</scenario_dragonfyre_times_finished>',
        'scenario_dragonfyre_last_duration': '<scenario_dragonfyre_last_duration>1014.997</scenario_dragonfyre_last_duration>',
        'scenario_dragonfyre_last_score': '<scenario_dragonfyre_last_score>2784</scenario_dragonfyre_last_score>',
        'scenario_dragonfyre_last_rating': '<scenario_dragonfyre_last_rating>5</scenario_dragonfyre_last_rating>',
        'scenario_dragonfyre_unlock_notified': '<scenario_dragonfyre_unlock_notified>2</scenario_dragonfyre_unlock_notified>',
        'scenario_dragonfyre_best_score': '<scenario_dragonfyre_best_score>2784</scenario_dragonfyre_best_score>',
        'scenario_dragonfyre_best_rating': '<scenario_dragonfyre_best_rating>5</scenario_dragonfyre_best_rating>',
        'scenario_dragonfyre_best_duration': '<scenario_dragonfyre_best_duration>1014.997</scenario_dragonfyre_best_duration>',
        'scenario_chapter_6_terminus_completed': '<scenario_chapter_6_terminus_completed>1</scenario_chapter_6_terminus_completed>',
        'hub_a6s1_complete': '<hub_a6s1_complete>76</hub_a6s1_complete>',
        'hub_a6s2_complete': '<hub_a6s2_complete>76</hub_a6s2_complete>',
        'hub_a6s3_complete': '<hub_a6s3_complete>76</hub_a6s3_complete>',
        'hub_a6s4_complete': '<hub_a6s4_complete>76</hub_a6s4_complete>',
        'hub_a7s3_complete': '<hub_a7s3_complete>76</hub_a7s3_complete>',
        'hub_a7s2_complete': '<hub_a7s2_complete>76</hub_a7s2_complete>',
        'hub_a7s4_complete': '<hub_a7s4_complete>76</hub_a7s4_complete>',
        'hub_a7s5_complete': '<hub_a7s5_complete>76</hub_a7s5_complete>',
        'hub_a7s1_complete': '<hub_a7s1_complete>76</hub_a7s1_complete>',
    }

    # Update the content
    updated_content = update_tags(content, new_tags)

    # Write updated content back
    try:
        with open(file_path, 'w', encoding='utf-8') as f:
            f.write(updated_content)
        print("\nSUCCESS: userdata.xml updated successfully!")
        print("All Timelines content has been unlocked.")
        print("\nPress Enter to exit...")
        input()
    except Exception as e:
        print(f"ERROR writing file: {e}")
        print("\nPress Enter to exit...")
        input()

if __name__ == "__main__":
    main()
