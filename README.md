qitana/ACT.Hojoring
=====
[![GitHub release](https://img.shields.io/github/release/qitana/ACT.Hojoring?cacheSeconds=3600)](https://github.com/qitana/ACT.Hojoring/releases/latest)
![GitHub Release Date](https://img.shields.io/github/release-date/qitana/ACT.Hojoring?cacheSeconds=3600)
![GitHub last commit](https://img.shields.io/github/last-commit/qitana/ACT.Hojoring?cacheSeconds=1800)
[![License](https://img.shields.io/badge/license-BSD--3--Clause-blue.svg)](https://github.com/qitana/ACT.Hojoring/blob/master/LICENSE)

Advanced Combat Tracker (ACT) の FFXIV向けプラグインの詰合せです。  
[オリジナル (anoyetta/ACT.Hojoring)](https://github.com/anoyetta/ACT.Hojoring) のフォーク(派生)版です。

# 概要

基本的な機能は[オリジナル版](https://github.com/anoyetta/ACT.Hojoring)と同じです。  
何ができるのかといった情報は[オリジナル版](https://github.com/anoyetta/ACT.Hojoring)を参照して下さい。

## 開発方針

機能を追加したりすることはありません。  
機能の追加・オリジナル版に存在している不具合の修正は、オリジナル版にPRを通して行います。

ここでは、オリジナル版の安定したリリースに対して、
- 使いやすいようにUIを修正
- 必要の無い機能の無効化
- 過去に使えていたが無効になった機能の復活

等を行うのみです。


## オリジナル版との相違点

- Activatorを無効化しました。 
- UIの調整 
  - 全体的にフォントサイズを小さめに変更しました。
  - UI上でConsolasを使わないように変更しました。
  - オリジナル版にてサポート等に使用されているボタンを削除しました。
- 起動時のスプラッシュスクリーン表示を無効化しました。 
- アップデートスクリプトを無効化しました。 
  - プラグインの配置方法によっては、アップデートスクリプトが破壊的な動作をするため。  
    アップデートがあった場合には、リリースページを表示するのみに変更しました。  
    アップデートは全て手動で行う必要があります。
- ホットバーからのリキャスト時間同期の精度向上 
- 抽出したDLLファイル `AquesTalkDriver.dll` を、`Advanced Combat Tracker.exe` と  
  同じフォルダに配置することで、本フォーク版でもAquesTalk (ゆっくり)を利用可能にしました。
  - オリジナル版 v7.7.2 から、AquesTalk (ゆっくり)の動作に必要となる  
    DLLファイル `AquesTalkDriver.dll` が `ACT.TTSYukkuri.dll` と結合されたため、  
    このDLLを抽出するためのプログラム `ATDExtractor` を追加しました。
- 無効化されていた Camera を使用できるようにしました。
- Hojoringの終了を高速にしました。
- カットシーン中はオーバーレイを非表示にするようにしました。


## オリジナルへ行った Pull Request

- Hotbar Information のページ未実装を修正しました。([anoyetta#239](https://github.com/anoyetta/ACT.Hojoring/pull/239))
- Voicetext Web Api のバージョンを修正しました。([anoyetta#248](https://github.com/anoyetta/ACT.Hojoring/pull/248))
- VoicePalette を実装しました。([anoyetta#251](https://github.com/anoyetta/ACT.Hojoring/pull/251))

## 注意事項

- 各プラグインは、オリジナル版と本フォーク版を同時に使用することはできません。  
  エラーが多発し、設定情報を失う等、致命的な問題を誘発する可能性があります。
- 本フォーク版では、オリジナル版のようなサポートは実施しません。

# 最新リリース

[![GitHub release](https://img.shields.io/github/release/qitana/ACT.Hojoring?style=for-the-badge&logo=github&cacheSeconds=3600)](https://github.com/qitana/ACT.Hojoring/releases/latest)

# インストール

詳細な手順はオリジナル版の [インストール手順（完全版）](https://www.anoyetta.com/entry/hojoring-setup) を参照してください。

# 使い方

オリジナル版のWiki等を参照してください。

[オリジナル版 Wiki](https://github.com/anoyetta/ACT.Hojoring/wiki) 
- [SpecialSpellTimer Wiki](https://github.com/anoyetta/ACT.Hojoring/wiki/SpecialSpellTimer)
- [TTSYukkuri Wiki](https://github.com/anoyetta/ACT.Hojoring/wiki/Yukkuri)
- [UltraScouter Wiki](https://github.com/anoyetta/ACT.Hojoring/wiki/UltraScouter)
- [TTSYukkuri Wiki](https://github.com/anoyetta/ACT.Hojoring/wiki/Yukkuri)
