import SwiftUI


struct TapTextView: View {
    @Binding var text: String
    @State private var originalText = ""
    @State private var draftText = ""
    @State private var isEditing = false
    @FocusState.Binding var focusedID: UUID?
    let fieldID :UUID
    let tapTime:Int = 2
    
    var body: some View {
        Group{
            if isEditing {
                TextField("编辑", text:$draftText)
                    .textFieldStyle(.roundedBorder)
                    .focused($focusedID,equals: fieldID)
                    .onSubmit {
                        commitEditing()
                    }
                    .onExitCommand {
                        cancelEditing()
                    }
                    .onChange(of: focusedID) {old, newID in
                        //焦点离开
                        if  newID != fieldID {
                            commitEditing()
                        }
                    }
            } else  {
                Text(text)
                    .onTapGesture(count: tapTime) {
                        startEditing()
                    }
            }
            Spacer()
        }

    }
    //点击Text
    private func startEditing(){
        draftText = text
        originalText = text
        focusedID = fieldID
        isEditing = true
    }
    //回车或失去焦点
    private func commitEditing() {
        //如果有修改则重新赋值给text触发自动保存
        if text != draftText{
            text = draftText
        }
        isEditing = false

    }
    //ESC退出编辑
    private func cancelEditing() {
        isEditing = false
    }
}
