;================Field================
;================ClassOrEnmum================
;================Package================
;by Bastian

class Field {
    __New(name, type) {
        this.name := name
        this.type := type
    }

    contents() {
        return % "name: " this.name " / type: " this.type
    }
}

class ClassOrEnum {
    fields := []
    operations := []
    isEnum := False
    package := ""

    __New(name, isEnum, byRef package) {
        this.name := name
        this.isEnum := isEnum
        this.package := package
    }

    addField(name, type) {
        field := new Field(name, type)
        this.fields.Push(field)
    }

    addOperation(name, type) {
        field := new Field(name, type)
        this.operations.Push(field)
    }

    getDescriptiveName() {
        if (this.isEnum)
            return "enum " this.name
        else
            return this.name
    }

    contents() {
        If this.isEnum
            type := "enum"
        Else
            type := "class"

        content := type " " this.name
        For i, item in this.fields
            content := content " / (" item.Contents() ")"

        return content
    }
}

class PackageRoot {
    classes := new OrderedDict()
    enums := new OrderedDict()
    root := ""

    getClass(className) {
        return this.classes.get(className)
    }

    addClass(byRef clazz) {
        this.classes.add(clazz.name, clazz)
    }

    classCount() {
        return this.classes.count()
    }

    getEnum(enumName) {
        return this.enums.get(enumName)
    }

    addEnum(byRef clazz) {
        this.enums.add(clazz.name, clazz)
    }

    enumCount() {
        return this.classes.count()
    }

    hasElements() {
        if (this.classCount() + this.enumCount() > 0) {
            return True
        } else {
            return False
        }
    }

    getRootPackage() {
        if (this.root == "") {
            this.root := new Package("root", "", this)
        }
        return this.root
    }

    getPackagesAsText(includeElementsCount := False, includeElements := False) {
        this.packagesAsText := ""
        this._getPackageAsText(this.root, 0, includeElementsCount, includeElements)
        return this.packagesAsText
    }

    ; internal methods
    _getPackageAsText(package, level, includeElementsCount := False, includeElements := False) {
        text := ""
        prefix := SubStr("----------------------------------------", 1, level * 2)
        text := text . prefix . package.name
        if (includeElementsCount) {
            text := text . "(c:" . package.classCount() . ", e:" . package.enumCount() . ")"
        }
        text := text . "`n"
        if (includeElements) {
            for className, class in package.classes {
                text := text . prefix . "  c " . className . "`n"
            }
            for enumName, enum in package.enums {
                text := text . prefix . "  e " . enumName . "`n"
            }
        }
        this.packagesAsText := this.packagesAsText . text

        for packageName, subPackage in package.packages {
            this._getPackageAsText(subPackage, level  + 1, includeElementsCount, includeElements)
        }
    }
}

class Package {
    name := ""
    parent := ""
    origin := ""
    classes := new OrderedDict()
    enums := new OrderedDict()
    packages := new OrderedDict()

    __New(name, byRef parent, byRef origin) {
        this.name := "pkg " . name
        this.parent := parent
        this.origin := origin
    }

    getClass(className) {
        return this.classes.get(className)
    }

    addClass(byRef clazz) {
        clazz.package := this
        this.classes.add(clazz.name, clazz)
        this.origin.addClass(clazz)
    }

    classCount() {
        return this.classes.count()
    }

    getEnum(enumName) {
        return this.enums.get(enumName)
    }

    addEnum(byRef clazz) {
        clazz.package := this
        this.enums.add(clazz.name, clazz)
        this.origin.addEnum(clazz)
    }

    enumCount() {
        return this.enums.count()
    }

    hasElements() {
        if (this.classCount() + this.enumCount() > 0) {
            return True
        } else {
            return False
        }
    }
    
    getPackage(packageName) {
        return this.packages.get(packageName)
    }

    addPackage(byRef package) {
        package.parent := this
        this.packages.add(package.name, package)
    }

    addNewPackage(package_name) {
        newPackage := new Package(package_name, this, this.origin)
        this.packages.add(newPackage.name, newPackage)
        return newPackage
    }

    removePackage(packageName) {
        this.packages.remove(packageName)
    }

    packageCount() {
        return this.packages.count()
    }

    exitStucture() {
        ; NOTE: this will remove the package with all its elements from the package structure
        for packageName, package in this.packages {
            this.parent.addPackage(package)
        }
        this.parent.removePackage(this.name)
    }
}


;================Unique Stack================
;by Bastian

class UniqueStack {
    maxSize := 3
    stack := []

    Push(newItem) {
        for i, item in this.stack
            if (item = newItem)
                this.stack.RemoveAt(i)

        if (this.stack.Count() >= this.maxSize)
            this.stack.RemoveAt(1)

        this.stack.Push(newItem)    
    }

    Count() {
        return this.stack.Count()
    }

    Contents() {
        content := ""
        for i, item in this.stack
            content := content item "; "
        return content
    }

    Size() {
        return this.stack.MaxIndex()
    }
}

;================OrderedDict================
class OrderedDict {
    keysInOrder := []
    valuesAsDict := []

    _NewEnum() {
        return new OrderedDict.ForwardEnumerator(this.keysInOrder, this.valuesAsDict)
    }

    class ForwardEnumerator {
        i := 0

        __New(keysInOrder, valuesAsDict) {
            this.keysInOrder := keysInOrder
            this.valuesAsDict := valuesAsDict
        }

        Next(ByRef k, ByRef v) {
            this.i := this.i + 1

            if (this.i > this.keysInOrder.maxIndex()) {
                return False
            }

            k := this.keysInOrder[this.i]
            v := this.valuesAsDict[k]

            return True
        }
    }

    add(key, value) {
        this.keysInOrder.Push(key)
        this.valuesAsDict[key] := value
    }

    get(key, fallBack := "") {
        if (this.valuesAsDict.hasKey(key)) {
            return this.valuesAsDict[key]
        } else {
            return fallBack
        }
    }

    remove(key) {
        this.valuesAsDict.delete(key)
        for i, found_key in this.keysInOrder {
            if (found_key == key) {
                this.keysInOrder.RemoveAt(i)
                break
            }
        }
    }

    count() {
        return this.keysInOrder.MaxIndex()
    }
}
