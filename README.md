声明：

1.首先，我对编程内容可谓是一窍不通，请以此为前提进行阅读。

2.起因是，我之前利用ai完成了一些游戏已失效mod的修复与本地化。所以我想能不能利用ai完成chapter master的汉化，现在你看到的这个粗糙版本就是我用ai完成的汉化。

3.本汉化的流程是，先翻译专有名词，然后让ai进行第一次汉化，之后我进入游戏验证汉化内容，确认成功实现和未实现的汉化，将未实现的汉化反馈给ai，ai再通过我提供的未汉化文本在源文件中查找，并对文本的代码进行替换，在localization中添加汉化。此工作是我在游戏中一个页面一个页面验证后实现，当然可能有更好的方法，但是我不知道（

4.目前一些主要页面和部分子页面内容完成了汉化。

已知问题：

1.部分动态文本，如名字和默认战团名没有汉化。

2.战斗日志内容没有能完全汉化，我尽力了，正如上文所言我对编程一窍不通。

3.中文长文本在翻译后不会自动换行，所以需要汉化时手动换行，目前建议是20-25字为一行。虽然我尽力让ai去调整文本的行数，但是应该有很多遗漏的地方，请见谅。

4.不知道是不是我gamemaker版本问题(IDE v2026.100.0.1110 Beta)，还是我操作不对（我也是第一次用gamemaker），字体与其背景框没有对齐，一般在文本框下一点的方向，很多标题与下方文本有重叠内容。我首先尝试了在gamemaker中缩放字体，但随后gamemaker卡死了。所以最后我用了最粗暴的方法，手动调整文本的位置。


我不知道我上传的文件是否对你有帮助，如果需要我上传其他文件，请直接告诉我。

如果你想对已有汉化文本进行修正你可以查看Chaptermaster-Ai\datafiles\main\localization下的zh-CN.json对已汉化内容进行修改。如果你手中的是游戏文件，该项目在ChapterMaster\main\localization下。

最后，我希望这对用ai进行老游戏文件的维护和本地化有启示，毕竟如上文所言，使用者是一个对编程一窍不通的纯小子（

最后的最后，如果有什么其他需要添加的东西也请告诉我，因为这也是我第一次在github上上传文件。
(本文件修改的版本为 ChapterMaster-main-2026-08-05-1356)


Statement:

1. First of all, I am completely clueless about programming, so please read this with that in mind.

2. The reason is, I previously used AI to fix and localize some outdated mods for games. So I wondered if I could use AI to localize Chapter Master into Chinese. The rough version you see now is the AI-based localization I completed.

3. The process of this localization was: first translating proper nouns, then letting AI do the first round of Chinese translation. After that, I entered the game to verify the translation, identified which translations were successful and which were not, and fed the untranslated parts back to AI. AI then searched for the untranslated text in the source files and replaced the text in the code, adding the Chinese localization in the localization files. This work was done by verifying each page in the game one by one. Of course, there might be better ways, but I don’t know them (

4. Currently, the main pages and some subpages have been localized into Chinese.

Known Issues:

1. Some dynamic texts, like names and default battalion names, are not localized.

2. The battle log content is not fully translated; I did my best. As mentioned above, I know nothing about programming.

3. Chinese long texts will not automatically wrap after translation, so you need to manually add line breaks during localization. Currently, the suggestion is 20-25 characters per line. Although I tried to have AI adjust the lines, there are probably many omissions, sorry about that.

4. I’m not sure if it’s an issue with my GameMaker version (IDE v2026.100.0.1110 Beta) or if I did something wrong (it’s also my first time using GameMaker), but the font doesn’t align with its background box. Usually, it’s slightly below the text box, and many titles overlap with the text below. I first tried scaling the font in GameMaker, but then it froze. So in the end, I just manually adjusted the text positions in the bluntest way.

I don’t know if the files I uploaded are helpful to you. If you need me to upload other files, just let me know.

If you want to fix the existing Chinese translation, you can check Chaptermaster-Ai\datafiles\main\localization zh-CN.json to modify the translated content. If you have the game files, the project is located in ChapterMaster\main\localization.

Finally, I hope this can provide some insight into using AI for maintaining and localizing old game files. As mentioned above, the user here is a complete noob when it comes to programming (

And last but not least, if there’s anything else you think should be added, please tell me, since this is also my first time uploading files on GitHub.
(This document is the modified version of ChapterMaster-main-2026-08-05-1356)
