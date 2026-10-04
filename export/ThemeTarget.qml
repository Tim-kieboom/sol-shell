import Quickshell
import Quickshell.Io
import QtQuick

// One file to generate: reads a template from this folder, replaces its {{name}}
// placeholders, and writes the result to the output folder. It writes again
// whenever a value it uses changes, because `rendered` is a binding.
Scope {
    id: root

    // file name of the template in export/, e.g. "wofi.css.tpl"
    required property string template
    // file name to write in the output folder, e.g. "wofi.css"
    required property string output
    // the folder to write to; nothing is written until `ready` is true
    required property string outputDir
    required property bool ready
    // name -> text, the replacements for the placeholders
    required property var values

    readonly property string outputPath: outputDir + "/" + output

    // Replace every {{name}} in a text. A name that does not exist is kept as it
    // is and reported, so a typo in a template is easy to spot.
    function render(text: string): string {
        return text.replace(/\{\{(\w+)\}\}/g, (whole, name) => {
            if (name in values)
                return values[name];
            console.warn("ThemeTarget " + template + ": unknown placeholder " + whole);
            return whole;
        });
    }

    FileView {
        id: templateFile
        path: Quickshell.shellPath("export/" + root.template)
        // editing a template while the shell runs updates the output
        watchChanges: true
        onFileChanged: reload()
    }

    FileView {
        id: outputFile
        path: root.outputPath
        // we only write this file, so a missing file at first start is no problem
        printErrors: false
    }

    // Recomputed whenever the template loads or any value it uses changes
    readonly property string rendered: templateFile.loaded ? render(templateFile.text()) : ""

    onRenderedChanged: write()
    onReadyChanged: write()

    function write(): void {
        if (ready && rendered !== "")
            outputFile.setText(rendered);
    }
}
