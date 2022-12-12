#NoEnv
#SingleInstance, Force
SendMode, Input
SetBatchLines, -1
SetWorkingDir, %A_ScriptDir%

#include include/data_structures.ahk
#include include/helper_functions.ahk
#Include include/WinClipAPI.ahk
#Include include/WinClip.ahk
#Include include/SetClipboardHTML.ahk

defaultPlantUmlFile := "plantuml\test.plantuml"
defaultLastUsedMax := 3

iniFile := "cmtke.ini"
IniRead, plantUmlFile, % iniFile, Main, InputFile, % defaultPlantUmlFile
IniRead, menuHotkey, % iniFile, Main, Hotkey, % defaultLastUsedMax
IniRead, lastUsedCount, % iniFile, Main, LastUsedMax, % defaultLastUsedMax
IniRead, formattingHTMLStart, % iniFile, Main, FormattingHTMLStart, % defaultLastUsedMax
IniRead, formattingHTMLEnd, % iniFile, Main, FormattingHTMLEnd, % defaultLastUsedMax
IniRead, lastUsedFromIni, % iniFile, LastUsed
lastUsedItems := []
for count, line in StrSplit(lastUsedFromIni, "`n", "`r") {
    lastUsedItems.Push(StrSplit(line, "=")[2])
}

FileGetTime, plantUmlFileLastChanged, % plantUmlFile

packageStructure := new PackageRoot()
parsePlantUml(plantUmlFile, packageStructure)

; OutputDebug, % packageStructure.getPackagesAsText(True, True)
packageToRemove := packageStructure.root.getPackage("pkg Domänenmodell")
if (packageToRemove) {
    packageToRemove.exitStucture()
}
; OutputDebug, % packageStructure.getPackagesAsText(True, False)

menuGen := New MenuGen(packageStructure)
menuGen.menuHandlerNothing := Func("menuHandlerNothing")
menuGen.menuHandlerOutputMenuAsCode := Func("menuHandlerOutputMenuAsCode").Bind(True)
menuGen.menuHandlerOutputMenuAsCodeNoLastUsed := Func("menuHandlerOutputMenuAsCode").Bind(False)
menuGen.menuHandlerField := Func("menuHandlerField")
menuGen.menuHandlerAllFieldsEnter := Func("menuHandlerAllFields").Bind(classesAndEnumsMap, "{Enter}")
menuGen.menuHandlerAllFieldsDown := Func("menuHandlerAllFields").Bind(classesAndEnumsMap, "{Down}")
menuGen.menuHandlerAllFieldsAltDown := Func("menuHandlerAllFields").Bind(classesAndEnumsMap, "!{Down}")
menuGen.setLastUsedCount(lastUsedCount)
menuGen.setLastUsed(lastUsedItems)

menuGen.buildMenu()

Hotkey % menuHotkey, openMenu, On
return

openMenu:
    ; check for changes
    FileGetTime, plantUmlFileCurrentLastChanged, % plantUmlFile
    if (plantUmlFileCurrentLastChanged != plantUmlFileLastChanged) {
        plantUmlFileLastChanged := plantUmlFileCurrentLastChanged
        
        packageStructure := new PackageRoot()
        parsePlantUml(plantUmlFile, packageStructure)
        menuGen.packageStructure := packageStructure
        menuGen.buildMenu()
    }

    Menu % menuGen.menuNameRoot, Show 
return


parsePlantUml(file, byRef packageStructure) {
    FileEncoding, UTF-8

    if (!FileExist(file)) {
        MsgBox, 48, , % "Kann Datei '" file "' nicht öffnen."
        Exit 1
    }

    currentNode := packageStructure.getRootPackage()

    Loop, Read, % file
    {
        word_array := StrSplit(Trim(A_LoopReadLine), A_Space)
        if (word_array[1] = "package") {
            ; new package starts
            currentNode := currentNode.addNewPackage(word_array[2])
        } else if (word_array[1] = "class" or word_array[1] = "enum") {
            ; new class starts
            currentClassOrEnum := new ClassOrEnum(word_array[2], word_array[1]="enum", currentNode)
            if (word_array[1] = "enum") {
                currentClassOrEnum.isEnum := true
            }
            workingOnClassOrEnum := true
        } else if (word_array[1] = "}") {
            if (workingOnClassOrEnum) {
                if (currentClassOrEnum.isEnum) {
                    currentNode.addEnum(currentClassOrEnum)
                } else {
                    currentNode.addClass(currentClassOrEnum)
                }
                workingOnClassOrEnum := false
            } else {
                ; package ends
                currentNode := currentNode.parent
            }
        } else if (workingOnClassOrEnum) {
            if (SubStr(word_array[1], 1, 2) != ".." and SubStr(word_array[1], 1, 2) != "--" and SubStr(word_array[1], 1, 2) != "==")
                if (currentClassOrEnum.isEnum)
                    currentClassOrEnum.addField(" ".join(word_array), "")
                else
                    if (inStr(word_array[2], "()"))
                        currentClassOrEnum.addOperation(word_array[2], word_array[1])
                    else
                        currentClassOrEnum.addField(word_array[1], word_array[3])
        }
    }
}

class MenuGen {
; Represents a menu tree, which displays a package structure with classes and enums and their fields
    packageIconBase64 := "iVBORw0KGgoAAAANSUhEUgAAAA4AAAAOCAMAAAAolt3jAAAAAXNSR0IArs4c6QAAAARnQU1BAACxjwv8YQUAAAAJUExURbB/QPzx7QAAAMlt5nIAAAADdFJOU///ANfKDUEAAAAJcEhZcwAADsIAAA7CARUoSoAAAAApSURBVBhXY2BCAUAuAwTAuYwgAONCeFA+kIsC4LIgQFsuCgC7DQqYmABYBwDKg74kzgAAAABJRU5ErkJggg=="
    classIconBase64 := "iVBORw0KGgoAAAANSUhEUgAAAA4AAAAOCAYAAAAfSC3RAAAAAXNSR0IArs4c6QAAAARnQU1BAACxjwv8YQUAAAAJcEhZcwAADsIAAA7CARUoSoAAAABgSURBVDhPY2SAgvCqg/+hTIJgZZs9XB9YIzEAZgETWBcZgDpO/ffrK0EMs4AFrAsJfOyeAGVBAH9pAZgGicPYKIBUGweBH/2DI6AsCNi4dgWYBonD2Chg8NtIZqjaMwIA3V8VRq2fL04AAAAASUVORK5CYII="
    enumIconBase64 := "iVBORw0KGgoAAAANSUhEUgAAAA4AAAAOCAMAAAAolt3jAAAAAXNSR0IArs4c6QAAAARnQU1BAACxjwv8YQUAAAAMUExURVd6web/4X0AAAAAAIv2psYAAAAEdFJOU////wBAKqn0AAAACXBIWXMAAA7CAAAOwgEVKEqAAAAAN0lEQVQYV2NgZkACzEDICAcQLhMQMDIAhaFcqCRcFsTELQsUQMjCAZiLBLDIArWBATF6kQAzMwBTDgDbfy0zIAAAAABJRU5ErkJggg=="
    fieldIconBase64 := "iVBORw0KGgoAAAANSUhEUgAAAA4AAAAOCAMAAAAolt3jAAAAAXNSR0IArs4c6QAAAARnQU1BAACxjwv8YQUAAAAPUExURYCjxtf5+Vd6wdP09AAAANndwFsAAAAFdFJOU/////8A+7YOUwAAAAlwSFlzAAAOwwAADsMBx2+oZAAAAEBJREFUGFd1zEkOACAIA0Cq/f+bxbIED3KATiAYn/oxQtGglDRAzhsXsJKppnuvQfPdZKheXSqIdMZUJ0NNFXkAAnMCbd1DoTYAAAAASUVORK5CYII="
    operationIconBase64 := "iVBORw0KGgoAAAANSUhEUgAAAA4AAAAOCAMAAAAolt3jAAAAAXNSR0IArs4c6QAAAARnQU1BAACxjwv8YQUAAAASUExURbeNt/Di94yMjLOKs3RIogAAALyBKV0AAAAGdFJOU///////ALO/pL8AAAAJcEhZcwAADsMAAA7DAcdvqGQAAABFSURBVBhXdcnRDsAgCEPRovD/v7y2iNke1kTDyUV99sc+hghfh4iw9daS7K4Yg41100DeymWaztZUdemySP0NTnqRq3oANMYC6l0rdgsAAAAASUVORK5CYII="
    menuHandlerNothing := ""
    menuHandlerOutputMenuAsCode := ""
    menuHandlerOutputMenuAsCodeNoLastUsed := ""
    menuHandlerField := ""
    menuHandlerAllFieldsEnter := ""
    menuHandlerAllFieldsDown := ""
    menuHandlerAllFieldsAltDown := ""
    menuNameRoot := ""
    menuNameLastUsed := "last used"
    menuNameAllFieldsEnter := "alle, mit Zeilenumbruch"
    menuNameAllFieldsDown := "alle, mit <Pfeil nach unten>"
    menuNameAllFieldsAltDown := "alle, mit <Alt><Pfeil nach unten>"
    lastUsedItems := new UniqueStack()
    existingMenus := []

    __New(ByRef packageStructure) {
        this.packageStructure := packageStructure
    }

    buildMenu() {
        if (this.menuNameRoot != "") {
            for key, value in this.existingMenus {
                Menu % key, Delete
            }
            existingMenus := []
        }
        this._createMenuClassesAndEnums()
        this._createMenuPackageStructure(this.packageStructure.root)
        this._createLastUsedMenu()
        this._createStandardEntries()
    }

    setLastUsedCount(count) {
        this.lastUsedItems.maxSize := count
    }

    setLastUsed(lastUsedItems) {
        for i, item in lastUsedItems {
            this.lastUsedItems.Push(item)
        }
    }

    updateLastUsedMenu(lastUsed := "") {
        ; remove placeholder
        try {
            Menu % this.menuNameRoot, Delete, % this.menuNameLastUsed
        } catch e {
            if (e.Message != "Nonexistent menu item.") {
                throw e
            }
        }

        ; remove previous entries
        for i, item in this.lastUsedItems.stack {
            try {
                Menu % this.menuNameRoot, Delete, % item
            } catch e {
                if (e.Message != "Nonexistent menu item.") {
                    throw e
                }
            }
        }

        if (lastUsed != "") {
            this.lastUsedItems.Push(lastUsed)
        }

        ; build all last used entries
        for i, item in this.lastUsedItems.stack {
            if (this.existingMenus.hasKey(item)) {
                Menu % this.menuNameRoot, Insert, 1&, % item, % ":" item
            }
        }
    }

    ; internal methods
    _createLastUsedMenu() {
        handler := this.menuHandlerNothing

        Menu % this.menuNameRoot, Insert, 1&, % this.menuNameLastUsed, % handler
        Menu % this.menuNameRoot, Disable, % this.menuNameLastUsed
        Menu % this.menuNameRoot, Insert, 2&

        if (this.lastUsedItems.size() > 0) {
            this.updateLastUsedMenu()
        }
    }

    _createStandardEntries() {
        handler := this.menuHandlerOutputMenuAsCodeNoLastUsed

        Menu % this.menuNameRoot, Add
        Menu % this.menuNameRoot, Add, <wahr>, % handler
        Menu % this.menuNameRoot, Add, <falsch>, % handler
        Menu % this.menuNameRoot, Add, <leer>, % handler
    }

    _createMenuClassesAndEnums() {
        if not (this.packageStructure.hasElements()) {
            MsgBox "No classes or enums found, this would result in an empty menu."
            exit
        }
        for className, clazz in this.packageStructure.classes {
            this._createMenuForClassOrEnum(clazz)
        }
        for enumName, enum in this.packageStructure.enums {
            this._createMenuForClassOrEnum(enum)
        }
    }

    _createMenuPackageStructure(currentNode) {
        for packageName, package in currentNode.packages {
            this._createMenuPackageStructure(package)
        }
        
        if (currentNode.parent) {
            Menu % currentNode.parent.name, Add, % currentNode.name, % ":" currentNode.name
            Menu % currentNode.parent.name, Icon, % currentNode.name, % "HICON:" Base64PNG_to_HICON(this.packageIconBase64),, 0
            this.existingMenus[currentNode.parent.name] := True
        } else {
            this.menuNameRoot := currentNode.name
        }
    }

    _createMenuForClassOrEnum(clazz) {
        menuHandlerOutputMenuAsCode := this.menuHandlerOutputMenuAsCode
        handlerField := this.menuHandlerField
        handlerAllFieldsEnter := this.menuHandlerAllFieldsEnter
        handlerAllFieldsDown := this.menuHandlerAllFieldsDown
        handlerAllFieldsAltDown := this.menuHandlerAllFieldsAltDown

        elementIconBase64 := clazz.isEnum ? this.enumIconBase64 : this.classIconBase64

        ; menu for the class or enum itself
        Menu % clazz.getDescriptiveName(), Add, % clazz.getDescriptiveName(), % menuHandlerOutputMenuAsCode
        Menu % clazz.getDescriptiveName(), Icon, % clazz.getDescriptiveName(), % "HICON:" Base64PNG_to_HICON(elementIconBase64),, 0
        Menu % clazz.getDescriptiveName(), Add
        this.existingMenus[clazz.getDescriptiveName()] := True

        ; menu for each field in the class or enum
        for i, field in clazz.fields {
            fieldName := clazz.isEnum ? field.name : field.name ": " field.type
            Menu % clazz.getDescriptiveName(), Add, % fieldName, % handlerField
            Menu % clazz.getDescriptiveName(), Icon, % fieldName, % "HICON:" Base64PNG_to_HICON(this.fieldIconBase64),, 0
        }

        ; menu for each operation in a class
        for i, field in clazz.operations {
            Menu % clazz.getDescriptiveName(), Add, % field.name, % handlerField
            Menu % clazz.getDescriptiveName(), Icon, % field.name, % "HICON:" Base64PNG_to_HICON(this.operationIconBase64),, 0
        }

        ; menu for overall functions
        if (clazz.fields.Length() > 1) {
            Menu % clazz.getDescriptiveName(), Add
            Menu % clazz.getDescriptiveName(), Add, % this.menuNameAllFieldsEnter, % handlerAllFieldsEnter
            Menu % clazz.getDescriptiveName(), Add, % this.menuNameAllFieldsDown, % handlerAllFieldsDown
            Menu % clazz.getDescriptiveName(), Add, % this.menuNameAllFieldsAltDown, % handlerAllFieldsAltDown
        }

        ; menu linking the class to the menu
        if (clazz.package.name == clazz.name) {
            MsgBox % "Classes with same name as package are not supported: " clazz.name
            exit
        }
        Menu % clazz.package.name, Add, % clazz.getDescriptiveName(), % ":" clazz.getDescriptiveName()
        Menu % clazz.package.name, Icon, % clazz.getDescriptiveName(), % "HICON:" Base64PNG_to_HICON(elementIconBase64),, 0
    }
}

updateLastUsed(MenuName) {
    global iniFile
    global menuGen
    menuGen.updateLastUsedMenu(MenuName)

    for i, item in menuGen.lastUsedItems.stack {
        IniWrite, % item, % iniFile, LastUsed, % i
    }
}

menuHandlerNothing(ItemName, ItemPos, MenuName) {
    return
}

menuHandlerOutputMenuAsCode(updateLastUsed, ItemName, ItemPos, MenuName) {
    if (updateLastUsed) {
        updateLastUsed(MenuName)
    }

    sendViaClip(htmlCodeTag(ItemName), ItemName)
    ; SendRaw % htmlCodeTag(MenuName)
}

menuHandlerField(ItemName, ItemPos, MenuName) {
    updateLastUsed(MenuName)

    content := getAttributeName(MenuName, ItemName)
    sendViaClip(htmlCodeTag(content), content)
    ; SendRaw % htmlCodeTag(content)
}

menuHandlerAllFields(classesAndEnumsMap, separatorKey, ItemName, ItemPos, MenuName) {
    updateLastUsed(MenuName)

    classOrEnum := classesAndEnumsMap[MenuName]

    for i, field in classOrEnum.fields {
        content := getAttributeName(MenuName, field.name)
        sendViaClip(htmlCodeTag(content), content)
        ; SendRaw % htmlCodeTag(content)
        SendInput % separatorKey
        Sleep 400
    }
}

getAttributeName(classOrEnumName, field) {
    word_array := StrSplit(classOrEnumName, A_Space)
    if (word_array[1] = "enum")
        return field
    else
        return classOrEnumName "." StrSplit(field, ":")[1]
}

sendViaClip(htmlContent, textContent) {
    WinClip.snap(clipData)

    ; this f...ing just stopped working - no clue as to why
    ; WinClip.SetHTML(content)
    SetClipboardHTML(htmlContent, , textContent)
    WinClip.Paste()
    
    Sleep 100
    WinClip.restore(clipData)
}

htmlCodeTag(content) {
    global formattingHTMLStart
    global formattingHTMLEnd

    content := StrReplace(content, "<", "&lt;")
    content := StrReplace(content, ">", "&gt;")
    return formattingHTMLStart . content . formattingHTMLEnd
}
