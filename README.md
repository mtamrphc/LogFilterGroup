# GroupFinder - WoW 1.12 Addon

A comprehensive chat parser addon for World of Warcraft 1.12 that automatically organizes LFG/LFM dungeon groups and profession service requests from chat channels.

## Features

### Dungeon Group Finder
- Automatically detects LFG/LFM messages in chat
- Recognizes all classic dungeons and raids (Deadmines, BRD, MC, BWL, etc.)
- Identifies tank/healer/DPS requests
- Shows player name, message, and time elapsed since last seen
- One-click whisper functionality

### Profession Services
- Detects profession service requests (LF BS, need enchanter, etc.)
- Recognizes offering messages (WTS, crafting services, etc.)
- Supports all classic professions: Blacksmithing, Tailoring, Alchemy, Enchanting, Engineering, Leatherworking, Jewelcrafting, Herbalism, Mining, Skinning
- Filters trade chat for relevant services

### Smart Features
- **Duplicate Prevention**: Updates existing messages instead of creating duplicates
- **Time Tracking**: Shows how long ago each message was seen (seconds, minutes, hours)
- **Auto-Cleanup**: Removes messages older than 30 minutes
- **Persistent Storage**: Saves messages between sessions
- **Tabbed Interface**: Switch between Dungeons and Professions views
- **Separate Windows**: Can split Dungeons and Professions into separate draggable windows
- **Scrollable Lists**: Browse through all collected messages
- **Quick Whisper**: Click "Whisper" button to instantly start a conversation

## Installation

1. Download the addon files
2. Extract the `GroupFinder` folder to your WoW addons directory:
   - Windows: `C:\Program Files\World of Warcraft\Interface\AddOns\`
   - Mac: `/Applications/World of Warcraft/Interface/AddOns/`
3. Restart WoW or reload UI with `/reload`

## File Structure

```
GroupFinder/
├── GroupFinder.toc    # Addon manifest
├── Core.lua           # Main addon logic and event handling
├── Parser.lua         # Chat message parsing and categorization
└── UI.lua             # User interface and display
```

## Usage

### Opening the Interface
- Type `/gf` or `/groupfinder` in chat
- The main window will appear with two tabs: **Dungeons** and **Professions**

### Navigation
- Click the **Dungeons** tab to view group finder messages
- Click the **Professions** tab to view profession service requests
- Click **Separate** to split into two independent windows
- Drag windows by clicking and dragging anywhere on the frame

### Interacting with Messages
- Each row shows:
  - **Player Name** (in green)
  - **Message Text** (their original message)
  - **Time Ago** (how long since the message was seen)
  - **Whisper Button** (click to start a conversation)
- Messages are sorted by most recent first
- Duplicate messages from the same player update the timestamp

### Commands
- `/gf` or `/groupfinder` - Toggle the main window
- `/gf clear` - Clear all messages for the current tab

### Clearing Messages
- Click the **Clear** button in the interface to remove all messages from the current view
- Messages are automatically cleaned after 30 minutes
- Use `/gf clear` to manually clear all messages

## Monitored Chat Channels

The addon monitors:
- **Trade Chat** (Channel messages)
- **Local Defense** (Channel messages)
- **General Chat** (Channel messages)
- **Yell** (Zone-wide announcements)
- **Say** (Local chat)

## Dungeon Keywords

The addon recognizes these dungeon-related terms:
- **Group Finder**: LFG, LFM, LF#M, LF#G
- **Roles**: tank, healer, dps, need, more, all
- **Dungeons**: Deadmines (DM), Wailing Caverns (WC), Ragefire Chasm (RFC), Shadowfang Keep (SFK), Blackfathom Deeps (BFD), Stockades, Gnomeregan, Razorfen Kraul (RFK), Razorfen Downs (RFD), Scarlet Monastery (SM), Uldaman, Zul'Farrak (ZF), Maraudon (Mara), Sunken Temple (ST), Blackrock Depths (BRD), Lower/Upper Blackrock Spire (LBRS/UBRS), Dire Maul, Stratholme (Strat), Scholomance (Scholo)
- **Raids**: Molten Core (MC), Onyxia (Ony), Blackwing Lair (BWL), Zul'Gurub (ZG), AQ20, AQ40, Naxxramas (Naxx)

## Profession Keywords

The addon recognizes:
- **Looking for**: LF BS, LF Tailor, LF Alch, LF Ench, LF Eng, LF LW, LF JC, Need [profession]
- **Offering**: Blacksmith, Tailor, Alchemist, Enchanter, Engineer, Leatherworker, Jewelcrafter
- **Trade Terms**: WTS (want to sell), WTB (want to buy), WTT (want to trade)
- **Service Terms**: PST (please send tell), crafting, your mats, tips appreciated, free, enchant, transmute

## Tips

1. **Keep it running**: The addon passively monitors chat, so just leave it running in the background
2. **Quick access**: Bind `/gf` to a hotkey for instant access
3. **Separate windows**: Use the "Separate" button when you want to monitor both dungeons and professions simultaneously
4. **Whisper quickly**: The whisper button pre-fills your chat with `/w [player]` so you can message instantly
5. **Stay organized**: Messages automatically clean up after 30 minutes, keeping your list fresh

## Troubleshooting

### Messages not appearing?
- Make sure you're in the correct chat channels
- Check that the addon is loaded with `/gf`
- Verify the keywords match common chat patterns on your server

### Interface not showing?
- Type `/reload` to reload your UI
- Check that all three .lua files are in the GroupFinder folder
- Make sure the .toc file is present and properly formatted

### Performance issues?
- Use `/gf clear` to manually clear old messages
- The addon automatically removes messages older than 30 minutes

## Customization

You can customize the addon by editing the Lua files:

- **Parser.lua**: Add or modify dungeon/profession keywords
- **UI.lua**: Adjust window size, colors, or layout
- **Core.lua**: Change auto-cleanup timer (default: 30 minutes)

## Version History

### Version 1.0
- Initial release
- Dungeon group finder
- Profession service finder
- Tabbed interface
- Separate window mode
- Auto-cleanup of old messages
- Persistent storage
- Quick whisper functionality

## Credits

Created for World of Warcraft 1.12 client
Compatible with all WoW 1.12 servers

## License

Free to use and modify for personal use.

---

**Enjoy finding groups and services faster with GroupFinder!**
