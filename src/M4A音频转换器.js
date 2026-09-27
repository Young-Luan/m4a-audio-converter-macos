ObjC.import("Foundation");

const app = Application.currentApplication();
app.includeStandardAdditions = true;

function shellQuote(value) {
  return "'" + String(value).replace(/'/g, "'\"'\"'") + "'";
}

function run() {
  try {
    const audioItems = app.chooseFile({
      withPrompt: "选择要转换的 M4A 音频（可多选）",
      multipleSelectionsAllowed: true,
    });

    const formatChoices = [
      "MP3｜通用播放",
      "WAV｜剪辑与语音识别",
      "FLAC｜无损存档",
    ];
    const selectedChoice = app.chooseFromList(formatChoices, {
      withTitle: "选择输出格式",
      withPrompt: "要转换成哪种格式？",
      defaultItems: [formatChoices[0]],
      okButtonName: "继续",
      cancelButtonName: "取消",
    });
    if (selectedChoice === false) return;

    const outputFolder = app.chooseFolder({
      withPrompt: "选择转换后文件的保存位置",
    });

    let outputFormat = "flac";
    if (selectedChoice[0].startsWith("MP3")) outputFormat = "mp3";
    if (selectedChoice[0].startsWith("WAV")) outputFormat = "wav";

    const resourcePath = $.NSBundle.mainBundle.resourcePath.js;
    const converterPath = resourcePath + "/convert_audio.sh";
    const outputPath = outputFolder.toString();
    const inputArguments = audioItems
      .map((audioItem) => shellQuote(audioItem.toString()))
      .join(" ");
    const commandText =
      shellQuote(converterPath) +
      " --format " + shellQuote(outputFormat) +
      " --output-dir " + shellQuote(outputPath) +
      " " + inputArguments;

    const resultText = app.doShellScript(commandText);
    const dialogResult = app.displayDialog(resultText, {
      withTitle: "M4A 音频转换器",
      buttons: ["打开输出文件夹", "完成"],
      defaultButton: "完成",
    });

    if (dialogResult.buttonReturned === "打开输出文件夹") {
      app.doShellScript("/usr/bin/open " + shellQuote(outputPath));
    }
  } catch (error) {
    if (error.errorNumber === -128) return;
    app.displayAlert("转换没有完成", {
      message: error.message || String(error),
      as: "critical",
    });
  }
}
