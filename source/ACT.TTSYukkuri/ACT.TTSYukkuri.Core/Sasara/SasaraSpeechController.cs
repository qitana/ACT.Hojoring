using System;
using ACT.TTSYukkuri.Config;
using FFXIV.Framework.TTS.Common;
using FFXIV.Framework.Bridge;

namespace ACT.TTSYukkuri.Sasara
{
    /// <summary>
    /// さとうささらスピーチコントローラ
    /// </summary>
    public class SasaraSpeechController :
        ISpeechController
    {
        /// <summary>
        /// 初期化する
        /// </summary>
        public void Initialize()
        {
            Settings.Default.SasaraSettings.SetToRemote();
        }

        public void Free()
        {
        }

        /// <summary>
        /// テキストを読み上げる
        /// </summary>
        /// <param name="text">読み上げるテキスト</param>
        public void Speak(
            string text,
            PlayDevices playDevice = PlayDevices.Both,
            bool isSync = false,
            float? volume = null)
            => Speak(text, playDevice, VoicePalettes.Default, isSync, volume);

        /// <summary>
        /// テキストを読み上げる
        /// </summary>
        /// <param name="text">読み上げるテキスト</param>
        public void Speak(
            string text,
            PlayDevices playDevice = PlayDevices.Both,
            VoicePalettes voicePalette = VoicePalettes.Default,
            bool isSync = false,
            float? volume = null)
        {
            if (string.IsNullOrWhiteSpace(text))
            {
                return;
            }

            // 現在の条件をハッシュ化してWAVEファイル名を作る
            var wave = this.GetCacheFileName(
                Settings.Default.TTS,
                text.Replace(Environment.NewLine, "+"),
                Settings.Default.SasaraSettings.ToString());

            this.CreateWaveWrapper(wave, () =>
            {
                // 音声waveファイルを生成する
                Settings.Default.SasaraSettings.SetToRemote();
                RemoteTTSClient.Instance.TTSModel.TextToWave(
                    TTSTypes.CeVIO,
                    text,
                    wave,
                    0,
                    Settings.Default.SasaraSettings.Gain);
            });

            // 再生する
            SoundPlayerWrapper.Play(wave, playDevice, isSync, volume);
        }
    }
}
