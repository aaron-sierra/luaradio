local os = require('os')
local io = require('io')
local radio = require('radio')

if #arg < 1 then
    io.stderr:write("Usage: " .. arg[0] .. " <FM radio frequency>\n")
    os.exit(1)
end

local frequency = tonumber(arg[1])

-- Frequency offset for offset tuning
local frequency_offset = -600e3

-- Channel LPF FIR filter taps (~190KHz)
local channel_taps = {-0.000379763941576, -0.000755343544641, -0.000960537583496, -0.000884240583024, -0.000426510157937, 0.000422217039728, 0.00149492356348, 0.00241785952975, 0.00268931749986, 0.00187400921058, -0.000145415585996, -0.00297140336566, -0.00567092109719, -0.00700412698984, -0.00587672384182, -0.00187791794729, 0.00431168821072, 0.010857977522, 0.0151789967781, 0.01477466045, 0.00825469368027, -0.00378757701136, -0.0184192455816, -0.030766896588, -0.0351725661079, -0.0268383682988, -0.00348265935507, 0.0335343007651, 0.0790406933162, 0.12499240886, 0.162328722801, 0.183247748354, 0.183247748354, 0.162328722801, 0.12499240886, 0.0790406933162, 0.0335343007651, -0.00348265935507, -0.0268383682988, -0.0351725661079, -0.030766896588, -0.0184192455816, -0.00378757701136, 0.00825469368027, 0.01477466045, 0.0151789967781, 0.010857977522, 0.00431168821072, -0.00187791794729, -0.00587672384182, -0.00700412698984, -0.00567092109719, -0.00297140336566, -0.000145415585996, 0.00187400921058, 0.00268931749986, 0.00241785952975, 0.00149492356348, 0.000422217039728, -0.000426510157937, -0.000884240583024, -0.000960537583496, -0.000755343544641, -0.000379763941576}

-- FM Deemphasis IIR filter taps (tau=75e-6)
local fm_deemph_b_taps = {0.03153663993126178, 0.03153663993126178}
local fm_deemph_a_taps = {1, -0.9369267201374764}

-- Audio LPF FIR filter taps (~15KHz)
local audio_lpf_taps = {0.00075568569312, 0.000853018327262, 0.000812720732952, 0.000584600746918, 0.000119238175979, -0.000591735599128, -0.00147275697005, -0.0023395095094, -0.00291078523528, -0.00286596690435, -0.00194194965193, -4.71059827451e-05, 0.002642096662, 0.0056392982044, 0.00819038372907, 0.00940955487226, 0.00849350214446, 0.00497189589487, -0.00106616501712, -0.00883499527818, -0.016857667655, -0.0231391774342, -0.0254944730171, -0.0219785537992, -0.0113344642415, 0.00663915466737, 0.0308912188923, 0.0591522012705, 0.0882126591354, 0.114407236411, 0.134218188996, 0.14488265174, 0.14488265174, 0.134218188996, 0.114407236411, 0.0882126591354, 0.0591522012705, 0.0308912188923, 0.00663915466737, -0.0113344642415, -0.0219785537992, -0.0254944730171, -0.0231391774342, -0.016857667655, -0.00883499527818, -0.00106616501712, 0.00497189589487, 0.00849350214446, 0.00940955487226, 0.00819038372907, 0.0056392982044, 0.002642096662, -4.71059827451e-05, -0.00194194965193, -0.00286596690435, -0.00291078523528, -0.0023395095094, -0.00147275697005, -0.000591735599128, 0.000119238175979, 0.000584600746918, 0.000812720732952, 0.000853018327262, 0.00075568569312}

--------------------------------------------------------------------------------

local b0 = radio.RtlSdrSourceBlock(frequency + frequency_offset, 2048000)
local b1 = radio.SignalSourceBlock({signal='exponential', frequency=frequency_offset}, 2048000)
local b2 = radio.MultiplierBlock()
local b3 = radio.FIRFilterBlock(channel_taps)
local b4 = radio.DownsamplerBlock(10)
local b5 = radio.FrequencyDiscriminatorBlock(10.0)
local b6 = radio.IIRFilterBlock(fm_deemph_b_taps, fm_deemph_a_taps)
local b7 = radio.FIRFilterBlock(audio_lpf_taps)
local b8 = radio.DownsamplerBlock(4)
local b9 = radio.PulseAudioSinkBlock()
local top = radio.CompositeBlock()

top:connect(b0, "out", b2, "in1")
top:connect(b1, "out", b2, "in2")
top:connect(b2, "out", b3, "in")
top:connect(b3, "out", b4, "in")
top:connect(b4, "out", b5, "in")
top:connect(b5, "out", b6, "in")
top:connect(b6, "out", b7, "in")
top:connect(b7, "out", b8, "in")
top:connect(b8, "out", b9, "in")
top:run(true)
