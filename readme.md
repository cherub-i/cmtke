# CMTKE - class modell to keyboard entry

## What is does

### The problem

When writing documentation, I constantly have to refer to classes, enums and their members (attributes, operations).  
These references need to be

- consistent to the naming given to the class, enum, attribute or operation in the class model
- exact (if there is a typo, it may cause confusion and will make it impossible to find the mentioning ot this object through text search later on)
- easily identifieable amidst other text - so ideally they should use a specific format

This all results in a lot of typing and double-checking.

### The idea

I wanted a tool that picks up the information from the already existing class model (in my case a file maintained in Enterprise Architect) and offers some kind of support for inputting the elements from that model via the keyboard.  
I explicitly looked for a solution that works on the keyboard-entry level, so that it is independent from where the content is used (may it be on a Wiki, Word-document, etc.).

### The solution

CMTKE is an Autohotkey-Script. When a shortcut-key is pressed, it opens up a menu that is structured after the class diagram:

- packages act as parent menus
- classes and enums with their members are the leaf-menus
- choosing a menu entry leads to the entry "being typed" (actually the content is passed trough the clipboard)

## Installation

1. get [Autohotkey](https://www.autohotkey.com/) in the 1.1.x version (I did not check if it runs with other version, maybe it does)
2. clone this repo (what you actually need is [`cmtke.ahk`](cmtke.ahk) and everything in the [include-folder](cmtke.ahk)
3. configure your setting in [`cmtke.ini`](cmtke.ini) - it should be pretty self-explanatory.

## Usage

The shortcut key opens up the menu, when you select a menu-entry, it will enter the text which represents that menu entry at the cursor position (unless you have a menu entry, that opens a submenu).

## References

I am using

- [WinClip](https://www.autohotkey.com/board/topic/74670-class-winclip-direct-clipboard-manipulations/)
- [SetClipboardHTML](https://www.autohotkey.com/boards/viewtopic.php?t=80706)
