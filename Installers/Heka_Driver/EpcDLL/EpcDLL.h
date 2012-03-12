/*
   HEKA Elektronik GmbH

   ##################################################################
   #####  Copyright 1990, 2011 by HEKA Elektronik               #####
   #####  All rights reserved                                   #####
   ##################################################################

   Commercial distribution and usage with written permission only.

   functions to control:
   - the HEKA amplifiers:
     -- EPC8
     -- EPC800
     -- EPC9
     -- EPC10
     -- EPC10USB
     -- EPC10Plus
   - the AD-boards:
     -- ITC-16
     -- ITC-18
     -- LIH1600
     -- LIH8+8
   - the digital trigger boxes:
     -- TIB14
     -- TIB14s
   - the sound generator:
     -- PSA12

   Date: 13-Apr-2011
*/

#ifndef EPCDLL_H
#define EPCDLL_H

#ifdef _WIN32
   #define EPC_Calling _stdcall
   #define EPC_Import
#else
   #define EPC_Calling
   #define EPC_Import __attribute__((weak_import))
#endif

#ifdef __cplusplus
extern "C"
{
#endif

// 1 byte long types (8 bit):
typedef unsigned char   EPC_BOOLEAN;
typedef unsigned char   EPC_CHAR;

// 2 byte long types (16 bit):
typedef signed short    EPC_INT16;
typedef unsigned short  EPC_SET16;

// 4 byte long types (32 bit):
typedef long            EPC_INT32;
typedef unsigned long   EPC_CARD32;
typedef void*           EPC_ADDR32;

// 8 byte long types (64 bit):
typedef double          EPC_LONGREAL;

// string types
typedef struct {EPC_CHAR a [16];} EPC_Str16;
typedef struct {EPC_CHAR a [256];} EPC_Str256;
typedef unsigned char* EPC_Str256Ptr;    // pointer to char[256]

// Variables of type EPC_BOOLEAN can be either
enum  // EPC_BOOLEAN
{
   EPC_FALSE                  = 0,
   EPC_TRUE                   = 1
};

// The definitions of amplifiers for the function
//    EPC9_InitializeAndCheckForLife
enum  // EPC9_AmplifierType
{
   EPC9_Epc7Ampl              = 0,
   EPC9_Epc8Ampl              = 1,
   EPC9_Epc9Ampl              = 2,
   EPC9_Epc10Ampl             = 3,
   EPC9_Epc10PlusAmpl         = 4,
   EPC9_Epc10USBAmpl          = 5
};

// Values returned by EPC9_InitializeAndCheckForLife
// EPC9_Success is returned upon success, i.e., no error occurred.
// EPC9_NoScaleFile and EPC9_NoCFastFile are returned, when E9SCALE and
// E9CFAST files, respectively, were not found with the give file path.
// EPC9_LIHInitFailed is returned, when the AD-board could not be
// initialized. Other error number may be returned. Errors are returned
// in the error message string in human readable form.
enum  // EPC9_ResultType 
{
   EPC9_Success               = 0,
   EPC9_LIHInitFailed         = 1,
   EPC9_FirmwareError         = 2,
   EPC9_NoScaleFile           = 3,
   EPC9_NoCFastFile           = 4
};

// Definitions for EPC9_SetMode
enum  // EPC9_ModeType
{
   EPC9_ModeVC                = 0,
   EPC9_ModeCC                = 1
};

// Definitions for EPC9_SetCSlowRange
enum  // EPC9_CSlowRangeType
{
   EPC9_CSlowOff              = 0,
   EPC9_CSlow30pF             = 1,
   EPC9_CSlow100pF            = 2,
   EPC9_CSlow1000pF           = 3
};

// Definitions for EPC9_SetCurrentGainIndex
enum  // EPC9_CurrentGainIndexType
{
   EPC9_Gain_0005             = 0,     // 0.005 pA/mV, low range
   EPC9_Gain_0010             = 1,     // 0.010 pA/mV, low range
   EPC9_Gain_0020             = 2,     // 0.020 pA/mV, low range
   EPC9_Gain_0050             = 3,     // 0.050 pA/mV, low range
   EPC9_Gain_0100             = 4,     // 0.100 pA/mV, low range
   EPC9_Gain_0200             = 5,     // 0.200 pA/mV, low range
                                    // value 6: spaceholder for a menu separation line
   EPC9_Gain_0500             = 7,     // 0.5 pA/mV, medium range
   EPC9_Gain_1                = 8,     // 1.0 pA/mV, medium range
   EPC9_Gain_2                = 9,     // 2.0 pA/mV, medium range
   EPC9_Gain_5                = 10,    // 5.0 pA/mV, medium range
   EPC9_Gain_10               = 11,    // 10 pA/mV, medium range
   EPC9_Gain_20               = 12,    // 20 pA/mV, medium range
                                    // value 13: spaceholder for a menu separation line
   EPC9_Gain_50               = 14,    // 50 pA/mV, high range
   EPC9_Gain_100              = 15,    // 100 pA/mV, high range
   EPC9_Gain_200              = 16,    // 200 pA/mV, high range
   EPC9_Gain_500              = 17,    // 500 pA/mV, high range
   EPC9_Gain_1000             = 18,    // 1000 pA/mV, high range
   EPC9_Gain_2000             = 19     // 2000 pA/mV, high range
};

// Definitions for EPC9_SetExtStimPath
enum  // EPC9_ExtStimPathType
{
   EPC9_ExtStimOff            = 0,
   EPC9_ExtStimStimDac        = 1,
   EPC9_ExtStimInput          = 2
};

// Definitions for EPC9_SetCCGain
enum  // EPC9_CCGainType
{
   EPC9_CC1pA                 = 0,
   EPC9_CC10pA                = 1,
   EPC9_CC100pA               = 2
};

// Definitions for EPC9_SetCCTrackTau
enum  // EPC9_CCTrackTauType
{
   EPC9_TauOff                = 0,
   EPC9_Tau1                  = 1,
   EPC9_Tau3                  = 2,
   EPC9_Tau10                 = 3,
   EPC9_Tau30                 = 4,
   EPC9_Tau100                = 5
};

// Definitions for EPC9_SetRsMode
enum  // EPC9_RsModeType
{
   EPC9_RsModeOff             = 0,
   EPC9_RsMode100us           = 1,
   EPC9_RsMode10us            = 2,
   EPC9_RsMode2us             = 3
};

// Definitions for EPC9_SetF1Index
enum  // EPC9_F1IndexType
{
   EPC9_F1Bessel100kHz        = 0,
   EPC9_F1Bessel30kHz         = 1,      
   EPC9_F1Bessel10kHz         = 2,
   EPC9_F1HQ30kHz             = 3
};

// Definitions for EPC9_E9BoardType
enum  // EPC9_E9BoardType
{
   EPC9_E9Board1              = 0,
   EPC9_E9Board2              = 1,
   EPC9_E9Board3              = 2,
   EPC9_E9Board4              = 3,
   EPC9_E9Board5              = 4,
   EPC9_E9Board6              = 5,
   EPC9_E9Board7              = 6,
   EPC9_E9Board8              = 7
};

// Definitions for EPC9_HasProperty
enum  // EPC9_PropertyType
{
   EPC9_HasCCFastSpeed        = 0,
   EPC9_HasLowCCRange         = 1,
   EPC9_HasHighCCRange        = 2,
   EPC9_HasInternalVmon       = 3,
   EPC9_HasCCTracking         = 4,
   EPC9_HasVmonX100           = 5,
   EPC9_HasCFastExtended      = 6,
   EPC9_Has3ElectrodeMode     = 7,
   EPC9_HasBathSense          = 8,
   EPC9_HasF2Bypass           = 9
};

// LIH_OptionsType
// Record used to pass options to the 2 initialization functions
//    EPC9_InitializeAndCheckForLife
//    LIH_InitializeInterface
typedef struct
{
   EPC_INT32 UseUSB;
   EPC_INT32 BoardNumber;
   EPC_INT32 FIFOSamples;
   EPC_INT32 MaxProbes;
   EPC_Str16 DeviceNumber;
   EPC_Str16 SerialNumber;
   EPC_INT32 ExternalScaling;
   EPC_ADDR32 DacScaling;
   EPC_ADDR32 AdcScaling;
} LIH_OptionsType;

typedef LIH_OptionsType* LIH_OptionsPtr;


// EPC9_DLLVersion
// Returns the version number of this EPCDLL.
EPC_INT32 EPC_Calling EPC9_DLLVersion( void ) EPC_Import;

/*
   EPC9_InitializeAndCheckForLife
      - Initializes the amplifier, e.g., EPC9 or EPC10
         "Amplifier" defines which amplifier is to be used:
            EPC9_Epc9Ampl
            EPC9_Epc10Ampl
            etc.
      - Returns the value "EPC9_Success", if the initialization succeeded;
        otherwise returns an error code, in which case the error description
        is returned in the "ErrorMessage" string.
      - If EPC9_InitializeAndCheckForLife returns the error EPC9_NoScaleFile
        or EPC9_NoCFastFile, one can try again to load the SCALE and CFAST
        files with the function EPC9_LoadScaleFiles.
      - The pointer "ErrorMessage" can be NUL or point to a string at least
        256 characters long. "ErrorMessage" will contain the message describing
        the result of the initialization in case an error occurred.
      - The pointer "PathToScaleFile" can be NUL or point to the file path
        of the E9SCALE and E9CFAST files. The path separator is "\" for Windows
        and "/" for MacOS (":" can be used for MacOS, when "System 9" style
        paths are to be used, e.g., when called from inside IGOR Pro).
        The path string must be end with the path separator.
      - The pointer "OptionsPtr" can be NUL or point to a struct containing
        the options to set for the acquisition board, and to get from
        the amplifier. Make sure to initialize all fields, best by setting the
        complete record to zero.
        -- OptionsPtr->UseUSB
               for ITC-16 and ITC-18: if set to true, use USB, otherwise PCI
        -- OptionsPtr->BoardNumber
               PCI slot index:
                  ITC-16:  PCI slot index = 0 (first found), 1 to 3
                  ITC-18:  PCI slot index = 0 (first found), 1 to 3
                  LIH1600: PCI slot index = 0 (first found), 1 to 8
                  LIH8+8:  see OptionsPtr->DeviceNumber
        -- OptionsPtr->FIFOSamples
               for LIH1600 and LIH88: maximal size of virtual FIFO buffer
        -- OptionsPtr->MaxProbes
               if a probe selector is connected to the amplifier(s):
                  maximal number of ProbeSelector positions per amplifier
        -- OptionsPtr->DeviceNumber
               for LIH8+8:
                  if empty and OptionsPtr->BoardNumber = 0: uses first device found,
                  if empty and OptionsPtr->BoardNumber > 0: uses nth device
                  if not empty: uses device with given DeviceNumber
                  upon function success, returns the USB device ID of used device.
        -- OptionsPtr->SerialNumber
               returns the amplifier serial number
        -- OptionsPtr->ExternalScaling
               for LIH88: if OptionsPtr->ExternalScaling = EPC_TRUE then raw DAC 
                  and ADC data are handled unscaled, i.e., the user has to scale 
                  the input and output data himself.
                  The correct scaling factor are:
                  - For internal scaling: 3200 units/volt.
                  - For external scaling: scaling factors as returned in the arrays
                    OptionsPtr->DacScaling and OptionsPtr->AdcScaling, see below.
       -- OptionsPtr->DacScaling
               Pointer to array of EPC_LONGREAL with a minimum length of 8.
               Returns scaling factors from volts to DAC-units for each DAC.
       -- OptionsPtr->AdcScaling
               Pointer to array of EPC_LONGREAL with a minimum length of 16.
               Returns scaling factors from ADC-units to volts for each ADC.
      - OptionsSize
        The size of the record pointed to by OptionsPtr.
        Can be zero, if OptionsPtr is nil, size of LIH_OptionsType otherwise.
*/
EPC_INT32 EPC_Calling EPC9_InitializeAndCheckForLife(
            EPC_Str256Ptr ErrorMessage, 
            EPC_INT32 Amplifier, 
            EPC_Str256Ptr PathToScaleFile,
            LIH_OptionsPtr OptionsPtr,
            EPC_INT32 OptionsSize ) EPC_Import;

// EPC9_LoadScaleFiles
// Loads the E9SCALE and E9CFAST files, if function EPC9_InitializeAndCheckForLife
// failed to load them.
// Returns the value "EPC9_Success", if the initialization succeeded;
// otherwise returns an error code.
EPC_INT32 EPC_Calling EPC9_LoadScaleFiles(
            EPC_Str256Ptr ErrorMessage,
            EPC_Str256Ptr PathToScaleFile ) EPC_Import;

// EPC9_ForceVersion
// Forces the code to set the defaults for the given amplifier version
// and the given amplifiers connected to rach1 and rack2.
// This function is to be called, when the amplifier is off-line.
// It allows the function EPC9_HasProperty to return correct properties,
// when the amplifier is off-line.
void EPC_Calling EPC9_ForceVersion(
            EPC_CHAR Version, 
            EPC_INT32 Rack1AmplBoards,
            EPC_INT32 Rack2AmplBoards ) EPC_Import;

// EPC9_HasProperty
// Returns true, if the inquired property is supported by the active amplifier.
// Requires that the amplifier is properly initialized. If the amplifier is
// off-line, the function EPC9_ForceVersion had to be issued, passing the
// amplifier version to be used.
// Definition of EPC9_PropertyType see above.
EPC_BOOLEAN EPC_Calling EPC9_HasProperty( EPC_INT32 Property ) EPC_Import;

// EPC9_Shutdown
// Sets the amplifier in a save mode, i.e. switches to VC-mode and sets all
// DAC outputs to zero, then terminates connections to drivers.
void EPC_Calling EPC9_Shutdown( void ) EPC_Import;

// EPC9_FlushCache
// Commands sent to the EPC9 and EPC10 are not immediately transmitted.
// The reason is that transmission takes time depending on bus type.
// To speed-up over-all performance, commands are cached and transmitted either when:
// 1. An acquisition command is issued to the interface, e.g. LIH_ReadAll or
//    LIH_StartStimAndSample. Or
// 2. EPC9_FlushCache is called.
void EPC_Calling EPC9_FlushCache( void ) EPC_Import;

// EPC9_FlushThenWait
// Flushes the command cache (see EPC9_FlushCache) then waits the given number of seconds.
void EPC_Calling EPC9_FlushThenWait( EPC_LONGREAL Seconds ) EPC_Import;

// EPC9_Reset
// Resets most amplifier settings to their default state, with the
// following exceptions:
// - Parameters affecting VHold are not reset, i.e.:
//    -- VHold
//    -- VpOffset
//    -- VLiquidJunction
//    -- CCTrackVHold
// - Values for CSlow and RSeries are preserved,
//   yet CSlowRange and RsMode ARE set to off.
// - CCFastSpeed
void EPC_Calling EPC9_Reset( void ) EPC_Import;

// EPC9_SetMode
// Sets voltage clamp or current clamp mode.
// Definition of EPC9_ModeType see above.
// Passing the parameter "Gently" = true will switch mode minimizing
// changes of clamp condition. Thus, switching from voltage clamp to
// current clamp will end in clamping to that current which was flowing
// before switching mode, and the resulting cell voltage will be similar
// to the clamping voltage before the mode change. Switching from
// current clamp to voltage clamp will set the measured cell voltage as
// the holding voltage after the mode change.
void EPC_Calling EPC9_SetMode( EPC_INT32 Mode, EPC_BOOLEAN Gently ) EPC_Import;

// EPC9_SetCurrentGain
// Sets the current gain of the amplifier.
// Gain is specified in Ohms, i.e., V/A.
// See also comment for EPC9_GetCurrentGain.
void EPC_Calling EPC9_SetCurrentGain( EPC_LONGREAL Gain ) EPC_Import;

// EPC9_SetCurrentGainIndex
// Sets the current gain of the amplifier.
// Gain is specified as list index, see definition of the
// EPC9_CurrentGainIndexType above.
void EPC_Calling EPC9_SetCurrentGainIndex( EPC_INT32 GainIndex ) EPC_Import;

// EPC9_SetCCGain
// Sets the current range the amplifier can output in current clamp mode.
// Gain range see definition of the EPC9_CCGainType above.
void EPC_Calling EPC9_SetCCGain( EPC_INT32 CCGain ) EPC_Import;

// EPC9_SetVHold
// Sets the holding potential in voltage clamp mode.  
// Please note that any voltage sent to the stimulus DA by one of the
// LIH functions below may overrule that VHold!
void EPC_Calling EPC9_SetVHold( EPC_LONGREAL Volts ) EPC_Import;

// EPC9_SetCCIHold
// Sets the clamping current in current clamp mode.
// Please note that any stimulus sent to the stimulus DA by one of the
// LIH functions below may overrule that CCIHold!
void EPC_Calling EPC9_SetCCIHold( EPC_LONGREAL Amperes ) EPC_Import;

// EPC9_SetVLiquidJunction
// Sets the liquid junction potential to be considered when performing
// EPC9_AutoVpOffset and EPC9_AutoSearch.
void EPC_Calling EPC9_SetVLiquidJunction( EPC_LONGREAL Volts ) EPC_Import;

// EPC9_SetVpOffset
// Sets the pipette offset compensation.
void EPC_Calling EPC9_SetVpOffset( EPC_LONGREAL Volts ) EPC_Import;

// EPC9_AutoVpOffset
// Performs a nulling of the pipette offset potential.
EPC_BOOLEAN EPC_Calling EPC9_AutoVpOffset( void ) EPC_Import;

// EPC9_AutoSearch 
// Repeats the nulling of the pipette offset potential.
// It assumes that a EPC9_AutoVpOffset has been called beforehand
// to set a good starting VpOffset value and StartingStep.
EPC_BOOLEAN EPC_Calling EPC9_AutoSearch( void ) EPC_Import;

// EPC9_SetCFastTot
// Sets the total of both CFast amplifier, i.e., it sets the
// total CFast compensation value.
void EPC_Calling EPC9_SetCFastTot( EPC_LONGREAL Farads ) EPC_Import;

// EPC9_SetCFastTau
// Sets the time constant of the CFast compensation.
void EPC_Calling EPC9_SetCFastTau( EPC_LONGREAL Seconds ) EPC_Import;

// EPC9_AutoCFast
// Performs one AutoCFast compensation.
// Returns true, if the 2 last iterations did change the
// compensation parameters by less than 2%.
EPC_BOOLEAN EPC_Calling EPC9_AutoCFast( void ) EPC_Import;

// EPC9_SetCSlowRange
// Sets the range of CSlow compensation, see definition
// of EPC9_CSlowRangeType above. 
void EPC_Calling EPC9_SetCSlowRange( EPC_INT32 CSlowRange ) EPC_Import;

// EPC9_SetCSlow
// Sets the value of CSlow compensation in farads.
void EPC_Calling EPC9_SetCSlow( EPC_LONGREAL Farads ) EPC_Import;

// EPC9_SetGSeries
// Sets the value of GSeries compensation in siemens.
// Please note: RSeries [Ohms] = 1 / GSeries [Siemens].
void EPC_Calling EPC9_SetGSeries( EPC_LONGREAL Siemens ) EPC_Import;

// EPC9_AutoCSlow
// Performs one AutoCSlow compensation.
// Returns true, if the 2 last iterations did change the
// compensation parameters by less than 2%.
// Uses the present settings of CSlow and GSeries as initial
// estimates. EPC9_AutoCSlow may fail, if those initial estimates
// are much too small for the actual patched cell. One can
// set better estimates using EPC9_SetCSlow and EPC9_SetGSeries
// commands. It is much better to supply too large values, than
// too small ones.
EPC_BOOLEAN EPC_Calling EPC9_AutoCSlow( void ) EPC_Import;

// EPC9_SetRsMode
// Sets the mode of RsCompensation, definition of EPC9_RsModeType
// see above.
void EPC_Calling EPC9_SetRsMode( EPC_INT32 RsMode ) EPC_Import;

// EPC9_SetRsFraction
// Sets the fraction of RSeries to compensate in the RsCompensation.
void EPC_Calling EPC9_SetRsFraction( EPC_LONGREAL Fraction ) EPC_Import;

// EPC9_AutoRsComp
// Performs EPC9_AutoRs compensation. Please consult
// the documentation describing the AutoRs compensation function.
EPC_BOOLEAN EPC_Calling EPC9_AutoRsComp( EPC_LONGREAL Overshoot, EPC_LONGREAL Backoff ) EPC_Import;

// EPC9_SetGLeak
// Sets GLeak compensation in siemens.
void EPC_Calling EPC9_SetGLeak( EPC_LONGREAL Siemens ) EPC_Import;

// AutoGLeak
// Performs one AutoGLeak compensation.
// Returns true, if successful, false otherwise.
EPC_BOOLEAN EPC_Calling EPC9_AutoGLeak( void ) EPC_Import;

// EPC9_SetF1Index
// Sets the Filter1 setting by its list index, definition of
// EPC9_F1IndexType see above.
// Please note that Filter1 should never be set when in current clamp
// mode, or when RsCompensation is active.
void EPC_Calling EPC9_SetF1Index( EPC_INT32 Filter1Index ) EPC_Import;

// EPC9_SetF1Bandwidth
// Sets that Filter1 setting which is nearest to the given
// bandwidth.
// Please note that Filter1 should never be set when in current clamp
// mode, or when RsCompensation is active.
void EPC_Calling EPC9_SetF1Bandwidth( EPC_LONGREAL Bandwidth ) EPC_Import;

// EPC9_SetF2Bandwidth
// Sets the Filter2 bandwidth.
void EPC_Calling EPC9_SetF2Bandwidth( EPC_LONGREAL Bandwidth ) EPC_Import;

// EPC9_SetF2Butterworth
// Sets the Filter2 response characteristics. True sets
// Butterworth characteristic, false sets Bessel.
void EPC_Calling EPC9_SetF2Butterworth( EPC_BOOLEAN SetButterworth ) EPC_Import;

// EPC9_SetStimFilterOn
// True activates the 20us risetime of stimulus filter, false reduces
// risetime to 2us.
void EPC_Calling EPC9_SetStimFilterOn( EPC_BOOLEAN StimFilterOn ) EPC_Import;

// EPC9_SetCCTrackHold
// Sets the potential to which clamp the voltage when performing LFVC,
// i.e. "Low Frequency Voltage Clamp" in current clamp mode.
void EPC_Calling EPC9_SetCCTrackHold( EPC_LONGREAL TrackVHold ) EPC_Import;

// EPC9_SetCCTrackTau
// Sets the speed of LFVC.
void EPC_Calling EPC9_SetCCTrackTau( EPC_INT32 CCTrackTau ) EPC_Import;

// EPC9_SetVmonX100
// The VOLTAGE MONITOR signal is amplified by 100, if VmonX100On is set
// to true.
// One can check, whether that option is supported by the active amplifier
// by checking with "EPC9_HasProperty( EPC9_HasVmonX100 )".
// This feature is supported by all EPC10/USB, EPC10/Plus, and by the
// EPC10 version "F" and higher.
void EPC_Calling EPC9_SetVmonX100( EPC_BOOLEAN VmonX100On ) EPC_Import;

// EPC9_SetCCFastSpeed
// Sets the speed of the CC mode. Affects only EPC9 version "C" and "D".
void EPC_Calling EPC9_SetCCFastSpeed( EPC_BOOLEAN CCSpeed ) EPC_Import;

// EPC9_SetExtStimPath
// Sets the stimulus path:
// 1. EPC9_ExtStimOff
// 1.1. Connects the stimulus DAC to the stimulus input.
// 1.2. Turns the external stimulus input off.
// 2. EPC9_ExtStimStimDac
// 2.1. Connects the "Test" DAC to the stimulus input.
// 2.2. Turns the external stimulus input off.
// 3. EPC9_ExtStimInput
// 3.1. Connects the stimulus DAC to the stimulus input.
// 3.2. Connects the external stimulus input to the stimulus input,
// 3.3. Thus, the 2 stimulus sources are added together.
// Definition of EPC9_ExtStimPathType see above.
void EPC_Calling EPC9_SetExtStimPath( EPC_LONGREAL Factor, EPC_INT32 StimPath ) EPC_Import;

// EPC9_SetCSlowCycles
// Sets the number of testing pulses averaged to measure the current
// response while performing an auto cslow compensation.
void EPC_Calling EPC9_SetCSlowCycles( EPC_INT32 Cycles ) EPC_Import;

// EPC9_SetCSlowPeak
// Sets the amplitude of testing pulses used to measure the current
// response while performing an auto cslow compensation.
void EPC_Calling EPC9_SetCSlowPeak( EPC_LONGREAL Peak ) EPC_Import;

// EPC9_SetTimeout
// Sets the number of seconds after which iterative functions will
// abort, e.g., all "auto" functions.
void EPC_Calling EPC9_SetTimeout( EPC_LONGREAL Timeout ) EPC_Import;

// EPC9_SetActiveBoard
// Support for multiple EPC amplifiers, e.g., EPC10/Doubles
// Make the given amplifier the "active" amplifier. Thus, after this
// command all EPC commands will be send to this amplifier, until
// another amplifier is made active.
void EPC_Calling EPC9_SetActiveBoard( EPC_INT32 E9Board ) EPC_Import;

// EPC9_SetSelector
// Set the position of the probe selector, if a probe selector is connected.
// The maximal number of probes must have been set in OptionPtr->MaxProbes.
// "Position" ranges from 1 to number of probes per amplifier.
void EPC_Calling EPC9_SetSelector( EPC_INT32 Position ) EPC_Import;

// EPC9_GetStimDacOffset
// Returns the number of DAC-units to add to a stimulus to be sent directly
// to the stimulus DAC via "LIH" functions.
// This value compensates various offsets depending on amplifier state.
// Thus, it should be called when the amplifier is in the state used
// to output that DAV value.
EPC_INT32 EPC_Calling EPC9_GetStimDacOffset( void ) EPC_Import;

// EPC9_GetMuxAdcOffset
// Returns the number of ADC-units to add to any trace read from the
// Mux-Adc to compensate for the Mux-amplifier offset.
EPC_INT32 EPC_Calling EPC9_GetMuxAdcOffset( void ) EPC_Import;

// EPC9_GetLastError
// Reports the error number of the last EPC function.
EPC_INT32 EPC_Calling EPC9_GetLastError( void ) EPC_Import;

// EPC9_GetErrorText
// Reports the error text describing the error, if an error occurred.
void EPC_Calling EPC9_GetErrorText( EPC_Str256Ptr Text ) EPC_Import;

// EPC9_GetClipping
// Reports the clipping status of the amplifier.
EPC_SET16 EPC_Calling EPC9_GetClipping( void ) EPC_Import;

// EPC9_GetIpip
// Measures and reports the current measured after Filter2.
EPC_LONGREAL EPC_Calling EPC9_GetIpip( EPC_INT32 Samples ) EPC_Import;  

// EPC9_GetIpip
// Measures and reports the voltage monitor value.
EPC_LONGREAL EPC_Calling EPC9_GetVmon( EPC_INT32 Samples ) EPC_Import;

// EPC9_GetRMSNoise
// Measures and reports the PRM noise at the probe input.
EPC_LONGREAL EPC_Calling EPC9_GetRMSNoise( void ) EPC_Import;

// The following "EPC_Get" functions return the active value set by
// the corresponding "EPC_Set" functions, see above.

EPC_INT32 EPC_Calling EPC9_GetMode( void ) EPC_Import;

// Returns the actual gain in units of Ohms (i.e. V/A).
// Use this value when converting ADC samples to current by
// dividing the ADC samples by this value. The values do differ from
// the values suggested by the standard gain ranges (e.g. 1.0 pA/mV),
// since they contain amplifier specific calibration corrections.
EPC_LONGREAL EPC_Calling EPC9_GetCurrentGain( void ) EPC_Import;

// See comment for EPC9_GetCurrentGain!
EPC_INT32 EPC_Calling EPC9_GetCurrentGainIndex( void ) EPC_Import;

EPC_INT32 EPC_Calling EPC9_GetCCGain( void ) EPC_Import;

EPC_LONGREAL EPC_Calling EPC9_GetVHold( void ) EPC_Import;

EPC_LONGREAL EPC_Calling EPC9_GetCCIHold( void ) EPC_Import;

EPC_LONGREAL EPC_Calling EPC9_GetVLiquidJunction( void ) EPC_Import;

EPC_LONGREAL EPC_Calling EPC9_GetVpOffset( void ) EPC_Import;

EPC_LONGREAL EPC_Calling EPC9_GetCFastTot( void ) EPC_Import;

EPC_LONGREAL EPC_Calling EPC9_GetCFastTau( void ) EPC_Import;

EPC_INT32 EPC_Calling EPC9_GetCSlowRange( void ) EPC_Import;

EPC_LONGREAL EPC_Calling EPC9_GetCSlow( void ) EPC_Import;

EPC_LONGREAL EPC_Calling EPC9_GetGSeries( void ) EPC_Import;

EPC_INT32 EPC_Calling EPC9_GetRsMode( void ) EPC_Import;

EPC_LONGREAL EPC_Calling EPC9_GetRsFraction( void ) EPC_Import;

EPC_LONGREAL EPC_Calling EPC9_GetGLeak( void ) EPC_Import;

EPC_INT32 EPC_Calling EPC9_GetF1Index( void ) EPC_Import;

EPC_LONGREAL EPC_Calling EPC9_GetF1Bandwidth( void ) EPC_Import;

EPC_LONGREAL EPC_Calling EPC9_GetF2Bandwidth( void ) EPC_Import;

EPC_BOOLEAN EPC_Calling EPC9_GetF2Butterworth( void ) EPC_Import;

EPC_BOOLEAN EPC_Calling EPC9_GetStimFilterOn( void ) EPC_Import;

EPC_LONGREAL EPC_Calling EPC9_GetCCTrackHold( void ) EPC_Import;

EPC_INT32 EPC_Calling EPC9_GetCCTrackTau( void ) EPC_Import;

EPC_BOOLEAN EPC_Calling EPC9_GetVmonX100( void ) EPC_Import;

EPC_BOOLEAN EPC_Calling EPC9_GetCCFastSpeed( void ) EPC_Import;

EPC_INT32 EPC_Calling EPC9_GetCSlowCycles( void ) EPC_Import;

EPC_LONGREAL EPC_Calling EPC9_GetCSlowPeak( void ) EPC_Import;

EPC_LONGREAL EPC_Calling EPC9_GetTimeout( void ) EPC_Import;

// EPC9_GetActiveBoard
// Returns the index of the active amplifier board.
EPC_INT32 EPC_Calling EPC9_GetActiveBoard( void ) EPC_Import;

// EPC9_GetBoards
// Returns the number of amplifier boards.
EPC_INT32 EPC_Calling EPC9_GetBoards( void ) EPC_Import;

// EPC9_GetSelector
// Returns the index of the active selector position board.
EPC_INT32 EPC_Calling EPC9_GetSelector( void ) EPC_Import;


// Definitions for controlling the EPC8 amplifier
// Use LIH_InitializeInterface to initialize the interface and
// establish connection to the EPC8 amplifier.

// Definitions for EPC8 filter type
enum  // EPC8_FilterType
{
   EPC8_Filter100Hz           = 0,
   EPC8_Filter300Hz           = 1,
   EPC8_Filter500Hz           = 2,
   EPC8_Filter700Hz           = 3,
   EPC8_Filter1kHz            = 4,
   EPC8_Filter3kHz            = 5,
   EPC8_Filter5kHz            = 6,
   EPC8_Filter7kHz            = 7,
   EPC8_Filter10kHz           = 8,
   EPC8_Filter20kHz           = 9,
   EPC8_Filter30kHz           = 10,
   EPC8_FilterFull            = 11
};

// Definitions for EPC8 gain type
enum  // EPC8_GainType
{
   EPC8_Gain_0005             = 0,  // 0.005 pA/mV, low range
   EPC8_Gain_0010             = 1,  // 0.010 pA/mV, low range
   EPC8_Gain_0020             = 2,  // 0.020 pA/mV, low range
   EPC8_Gain_0050             = 3,  // 0.050 pA/mV, low range
   EPC8_Gain_0100             = 4,  // 0.100 pA/mV, low range
   EPC8_Gain_0200             = 5,  // 0.200 pA/mV, low range
   EPC8_Gain_0500             = 7,  // 0.5 pA/mV, medium range
   EPC8_Gain_1                = 8,  // 1.0 pA/mV, medium range
   EPC8_Gain_2                = 9,  // 2.0 pA/mV, medium range
   EPC8_Gain_5                = 10, // 5.0 pA/mV, medium range
   EPC8_Gain_10               = 11, // 10 pA/mV, medium range
   EPC8_Gain_20               = 12, // 20 pA/mV, medium range
   EPC8_Gain_50               = 14, // 50 pA/mV, high range
   EPC8_Gain_100              = 15, // 100 pA/mV, high range
   EPC8_Gain_200              = 16, // 200 pA/mV, high range
   EPC8_Gain_500              = 17, // 500 pA/mV, high range
   EPC8_Gain_1000             = 18  // 1000 pA/mV, high range
};

// Definitions for EPC8 mode type
enum  // EPC8_ModeType
{
   EPC8_ModeTest              = 0,
   EPC8_ModeSearch            = 1,
   EPC8_ModeVC                = 2,
   EPC8_ModeCC                = 3,
   EPC8_ModeCCcomm            = 4,
   EPC8_ModeCCFast            = 5
};

// EPC8_DecodeFilter
// Extract the filter setting from the digital input port obtained by 
// LIH_ReadDigital or LIH_ReadAll.
// Definition of EPC8_FilterType see above.
EPC_INT32 EPC_Calling EPC8_DecodeFilter( EPC_SET16 AllBits ) EPC_Import;

// EPC8_EncodeFilter
// Generates the bit pattern required by EPC8_SendToEpc8 to set the
// filter setting.
// Definition of EPC8_FilterType see above.
EPC_SET16 EPC_Calling EPC8_EncodeFilter( EPC_INT32 Filter ) EPC_Import;

// EPC8_DecodeGain
// Extract the gain setting from the digital input port obtained by 
// LIH_ReadDigital or LIH_ReadAll.
// Definition of EPC8_GainType see above.
EPC_INT32 EPC_Calling EPC8_DecodeGain( EPC_SET16 AllBits ) EPC_Import;

// EPC8_EncodeGain
// Generates the bit pattern required by EPC8_SendToEpc8 to set the
// gain setting. The 2 bit patters have to be sent in 2 sequential
// calls to EPC8_SendToEpc8.
// Definition of EPC8_GainType see above.
void EPC_Calling EPC8_EncodeGain(
            EPC_INT32 Gain, 
            EPC_SET16 *Bits1, 
            EPC_SET16 *Bits2 ) EPC_Import;

// EPC8_DecodeMode
// Extract the mode setting from the digital input port obtained by 
// LIH_ReadDigital or LIH_ReadAll.
// Definition of EPC8_ModeType see above.
EPC_INT32 EPC_Calling EPC8_DecodeMode( EPC_SET16 AllBits ) EPC_Import;

// EPC8_EncodeMode
// Generates the bit pattern required by EPC8_SendToEpc8 to set the
// mode setting.
// Definition of EPC8_ModeType see above.
EPC_SET16 EPC_Calling EPC8_EncodeMode( EPC_INT32 ModeToSet ) EPC_Import;

// EPC8_DecodeRemote
// Extract the remote status from the digital input port obtained by 
// LIH_ReadDigital or LIH_ReadAll.
EPC_BOOLEAN EPC_Calling EPC8_DecodeRemote( EPC_SET16 AllBits ) EPC_Import;

// EPC8_EncodeRemote
// Generates the bit pattern required by EPC8_SendToEpc8 to set the
// remote status.
EPC_SET16 EPC_Calling EPC8_EncodeRemote( EPC_BOOLEAN RemoteActive ) EPC_Import;

// EPC8_SendToEpc8
// Sends the given bit pattern to the EPC8 via the digital output port.
void EPC_Calling EPC8_SendToEpc8( EPC_SET16 Epc8Value ) EPC_Import;


// Definitions for controlling the EPC800 amplifier
// EPC_Str64
// The string type to communicate with the EPC800.
typedef struct {EPC_CHAR a [64];} EPC_Str64;
typedef unsigned char* EPC_Str64Ptr;    // pointer to char[64]

// Epc800_IsOpen
// Returns whether the connection to the EPC800 is open.
EPC_BOOLEAN EPC_Calling Epc800_IsOpen( void ) EPC_Import;

// Epc800_AppendToOutputFifo
// Adds the given command to the output stack to be sent out when possible.
void EPC_Calling Epc800_AppendToOutputFifo( EPC_Str64Ptr Command ) EPC_Import;

// Epc800_PeriodicTask
// Function to be called periodically.
// Reports error conditions:
// - Detached: is TRUE, if the device was detached from the USB.
// - InputOverflow is TRUE, if the input stach did overflow.
// - CommandWhenEmpty is the command to be sent out, when the output stack is
//   empty and a command can be sent to the EPC800.
// - CommandSent is TRUE, if CommandWhenEmpty was sceduled to be sent out.
// - InputCommand is the next recieved command on the input stack. 
void EPC_Calling Epc800_PeriodicTask(
            EPC_BOOLEAN *Detached,
            EPC_BOOLEAN *InputOverflow,
            EPC_Str64Ptr CommandWhenEmpty,
            EPC_BOOLEAN *CommandSent,
            EPC_Str64Ptr InputCommand ) EPC_Import;

// Epc800_Initialize
// Estabishes a connection to the EPC800 on the USB bus.
// Reports TRUE, if connecting was successfull.
EPC_BOOLEAN EPC_Calling Epc800_Initialize( void ) EPC_Import;

// Epc800_Flush
// Removes all commands in the input and output stcks.
void EPC_Calling Epc800_Flush( void ) EPC_Import;

// Epc800_Shutdown
// Shuts down the connection to the EPC800.
void EPC_Calling Epc800_Shutdown( void ) EPC_Import;


// Definitions for the DA/AD interfaces
enum  // LIH_ResultType 
{
   LIH_Success                = 0
};

// Definitions for DAC and ADC channel numbering:
enum
{
   LIH_MaxAdcChannels         = 16,
   LIH_MaxDacChannels         = 8
};

enum  // LIH_DigitalChannelType
{
   LIH_DigitalInChannel       = 16,
   LIH_DigitalOutChannel      = 8,
   // for second unit:
   LIH_DigitalInChannel_2     = 19,
   LIH_DigitalOutChannel_2    = 11
};

// Definitions of AcquisitionMode values:
enum  // LIH_AcquisitionModeType
{
   LIH_EnableDacOutput        = 1,
   LIH_DontStopDacOnUnderrun  = 2,
   LIH_DontStopAdcOnOverrun   = 4,
   LIH_TriggeredAcquisition   = 8
};

// Definitions of AcquisitionMode values:
enum  // LIH_BoardType
{
   LIH_ITC16Board             = 0,
   LIH_ITC18Board             = 1,
   LIH_LIH1600Board           = 2,
   LIH_LIH88Board             = 3
};

// Definitions of interface status:
enum  // LIH_StatusType
{
   LIH_StatusUnknown          = 0,
   LIH_StatusLocked           = 1,
   LIH_StatusIdle             = 2,
   LIH_StatusBusy             = 3,
   LIH_StatusAdcOverflow      = 4
};

// Definitions of AdcInputRange values:
enum  // LIH_AdcInputRangeType
{
   LIH_AdcRange10V            = 0,  // input range +/- 10.24V
   LIH_AdcRange5V             = 1,  // input range +/- 5.012V
   LIH_AdcRange2V             = 2,  // input range +/- 2.048V
   LIH_AdcRange1V             = 3   // input range +/- 1.024V
};

/*
   LIH_InitializeInterface
      - Initializes the AD board
      - Amplifier defines which amplifier is to be used:
            EPC9_Epc7Ampl
            EPC9_Epc8Ampl
      - ADBoard defines which AD board is to be used:
            LIH_ITC16Board
            LIH_ITC18Board
            LIH_LIH1600Board
            LIH_LIH88Board
      - Returns the value "LIH_Success", if the initialization succeeded;
        otherwise returns an error code, in which case the error description
        is returned in the "ErrorMessage" string.
      - The pointer "ErrorMessage" can be NUL or point to a string at least
        256 characters long. "ErrorMessage" will contain the message describing
        the result of the initialization in case an error occurred.
      - The pointer "OptionsPtr" can be NUL or point to a struct containing
        the options to set for the acquisition board, and to get from it.
        Make sure to initialize all fields, best by setting the complete record
        to zero.
        -- OptionsPtr->UseUSB
               for ITC-16 and ITC-18: if set to 1, use USB, otherwise PCI
        -- OptionsPtr->BoardNumber
               for ITC-16, ITC-18, and LIH1600:
                  PCI slot index, index 0 means "first device found"
               for LIH8+8: should be zero, see OptionsPtr->DeviceNumber below
        -- OptionsPtr->FIFOSamples
               for LIH1600 and LIH8+8: size of virtual FIFO buffer
        -- OptionsPtr->MaxProbes
               ignored
        -- OptionsPtr->DeviceNumber
               for LIH8+8, if not empty:
                  sets the USB device ID
               for LIH8+8, if empty:
                  gets the USB device ID:
                     OptionsPtr->DeviceNumber 0 means "first device encountered",
                     otherwise use device at position OptionsPtr->DeviceNumber.
                     OptionsPtr->DeviceNumber should only be used to enumerate all device
                     in a loop. Position in USB-BUS enumeration may not be reliable.
        -- OptionsPtr->SerialNumber
               returns the amplifier serial number
        -- OptionsPtr->ExternalScaling
               for LIH88: if OptionsPtr->ExternalScaling = EPC_TRUE then raw DAC 
                  and ADC data are handled unscaled, i.e., the user has to scale 
                  the input and output data himself.
                  The correct scaling factor are:
                  - For internal scaling: 3200 units/volt.
                  - For external scaling: scaling factors as returned in the arrays
                    OptionsPtr->DacScaling and OptionsPtr->AdcScaling, see below.
        -- OptionsPtr->DacScaling
               Pointer to array of EPC_LONGREAL with a minimum length of 8.
               Returns scaling factors from volts to DAC-units for each DAC.
        -- OptionsPtr->AdcScaling
               Pointer to array of EPC_LONGREAL with a minimum length of 16.
               Returns scaling factors from ADC-units to volts for each ADC.
      - OptionsSize
        The size of the record pointed to by OptionsPtr.
        Can be zero, if OptionsPtr is nil, size of LIH_OptionsType otherwise.
*/
EPC_INT32 EPC_Calling LIH_InitializeInterface(
            EPC_Str256Ptr ErrorMessage,
            EPC_INT32 Amplifier, 
            EPC_INT32 ADBoard,
            LIH_OptionsPtr OptionsPtr,
            EPC_INT32 OptionsSize ) EPC_Import;

// LIH_Shutdown
// Sets the interface in a save mode (e.g. sets all DAC to zero),
// then terminates connections to drivers.
void EPC_Calling LIH_Shutdown( void ) EPC_Import;


/*
   LIH_PhysicalChannels
      - Returns the actual number of channels used.
 
      Comments
        - Physical ADC and DAC channel number
          The number of ADC and DAC channels used may be larger than the ones
          the user is stating. The reason is that an acquisition model is used
          in which all channels are kept synchronous as much as possible. Thus,
          the ADC and DAC channels have to have common multipliers. Also, sampling
          intervals are to use useful multiplication factors / behavior.
        - Abstraction level
          All supported AD-boards are to display common behavior as similar as
          possible. 
        These reasons lead to some restrains on the actually used number of ADC
        and DAC channels, and on the sampling rates. Thus, some combinations of
        ADC and DAC channels are extended to yield the desired behavior. "Odd"
        ADC and DAC channel numbers are extended to "better behaved" combinations.
        "Better behaved" is essentially described as being a multiple of
        1, 2, 4, 5, 8, 10, 16, 20.
 */
EPC_INT32 EPC_Calling LIH_PhysicalChannels(
            EPC_INT32 DacChannelNo,
            EPC_INT32 AdcChannelNo ) EPC_Import;

/*
   LIH_StartStimAndSample
      - Starts stimulation and acquisition
      - "DacChannelNumber" is the number of DA channels to stimulate.
      - "AdcChannelNumber" is the number of AD channels to read.
      - "DacSamplesPerChannel" is the number of DA values to copy into the
        DAC FIFO for each used DacChannel, if "LIH_EnableDacOutput" is set
        in "AcquisitionMode".
        The value defined here defines the maximal number of DAC samples
        which may be filled into the DAC FIFO. The function LIH_AppendToFIFO
        should never append more data to the DAC FIFO than ADC samples
        read out from the ADC FIFO
      - "AdcSamplesPerChannel" is the number of AD values to read in pulsed
        acquisition mode, i.e. when "ReadContinuously" = 0.
      - "AcquisitionMode": bits defining the acquisition modes of the LIH,
        see LIH_AcquisitionModeType definitions above.
      - "DacChannels": a pointer to an array of EPC_INT16 containing the DAC to
        stimulate. DAC channel numbering is for analoge channels from 0 to 4
        for the 1. unit, 5 to 8 for the second unit, and for digital channels
        see definitions of LIH_DigitalChannelType above.
        It is NOT allowed to issue stimulation of the same DAC twice.
      - "AdcChannels": a pointer to an array of EPC_INT16 containing the ADC to
        read from. ADC channel numbering is for analoge channels from 0 to 8
        for the 1. unit, 9 to 15 for the second unit, and for digital channels
        see definitions of LIH_DigitalChannelType above.
        It is NOT allowed to issue acquisition from the same ADC twice.
      - "SampleInterval" defines the sampling interval between samples of
        one ADC reading, i.e. to read from 2 AD with a sampling interval
        of 1.0 ms, "SampleInterval", although the hardware may run at a
        different speed, e.g. the ITC-16 would run at 0.5 ms.
        "SampleInterval" should be within the conditions set by the hardware
        (LIH_GetBoardInfo gives you the required parameters). It will be
        changed otherwise to return the same value as LIH_CheckSampleInterval
        would return.
      - "OutData" is a pointer to an array of ADDRESSes, each element being
        the address of one DA-template.
        There must be least "DacChannelNumber" templates in that array.
      - "Immediate": if = 1, tells the driver to execute the acquisition in
        blocking mode, i.e., the function loads the FIFO, start acquiring,
        waits for the data to be in, then reads the ADC data from the FIFO,
        while blocking the bus for other tasks. The ADC data will be returned
        in "InData" in this case.
        "Immediate" will be true (i.e. 1) upon function return, if "Immediate"
        mode was possible.
      - "SetStimEnd": if = 1, tells the driver, that the DAC templates are
        not to be appended to. The reason is that a number of DAC values may
        (e.g. one sample for the ITC-16) may not be sent to the DAC at the
        end of the stimulation, if the driver is not told to handle that
        border situation.
        Generally:
          SetStimEnd = 1 for pulsed acquisition
          SetStimEnd = 0 for continuous acquisition
      - "ReadContinuously": defines whether continuous acquisition is asked
        for.
          ReadContinuously = 0 for pulsed acquisition
          ReadContinuously = 1 for continuous acquisition
      - The larger of "DacSamplesPerChannel" and "AdcSamplesPerChannel" defines
        the sizes of internal buffers. When appending DAC-data later with
        LIH_AppendToFIFO, one should never append more data than
        LIH_AvailableStimAndSample did return.
      - Returns true, if successful, false otherwise.

      WARNING:
        When requesting "Immediate" mode, one must check the "Immediate" value,
        when the function returns. "Immediate" will be false (i.e. 0), if
        conditions did not allow immediate acquisition. "Immediate" is supported
        only by few boards (e.g. ITC-1600 and LIH8+8) and only for simple
        acquisitions (short acquisition duration, no external trigger,
        limitations on number of channels and samples, etc.).
        "Immediate" is needed by those boards, which have sizable latencies
        in its normal acquisition mode. It allows to execute short acquisitions
        (setting one DAC, reading few samples from few ADC) with minimal latency.
 */
EPC_BOOLEAN EPC_Calling LIH_StartStimAndSample(
           EPC_INT32 DacChannelNumber,
           EPC_INT32 AdcChannelNumber,
           EPC_INT32 DacSamplesPerChannel,
           EPC_INT32 AdcSamplesPerChannel,
           EPC_SET16 AcquisitionMode,
           EPC_ADDR32 DacChannels,
           EPC_ADDR32 AdcChannels,
           EPC_LONGREAL *SampleInterval,
           EPC_ADDR32 OutData,
           EPC_ADDR32 InData,            // for Immediate mode only
           EPC_BOOLEAN *Immediate,
           EPC_BOOLEAN SetStimEnd,
           EPC_BOOLEAN ReadContinuously ) EPC_Import;

/*
   LIH_StartStimAndSample_ml
      - Equivalent to LIH_StartStimAndSample
        Helper function for languages not supporting vectors, i.e. array of ADDRESSes,
        such as MatLab.
      - OutData and InData vectors defined as the equivaluent array elements.
*/
EPC_BOOLEAN EPC_Calling LIH_StartStimAndSample_ml(
           EPC_INT32 DacChannelNumber,
           EPC_INT32 AdcChannelNumber,
           EPC_INT32 DacSamplesPerChannel,
           EPC_INT32 AdcSamplesPerChannel,
           EPC_SET16 AcquisitionMode,
           EPC_ADDR32 DacChannels,
           EPC_ADDR32 AdcChannels,
           EPC_LONGREAL *SampleInterval,
           EPC_ADDR32 OutData0,
           EPC_ADDR32 OutData1,
           EPC_ADDR32 OutData2,
           EPC_ADDR32 OutData3,
           EPC_ADDR32 InData0,
           EPC_ADDR32 InData1,
           EPC_ADDR32 InData2,
           EPC_ADDR32 InData3,
           EPC_ADDR32 InData4,
           EPC_ADDR32 InData5,
           EPC_ADDR32 InData6,
           EPC_ADDR32 InData7,
           EPC_BOOLEAN *Immediate,
           EPC_BOOLEAN SetStimEnd,
           EPC_BOOLEAN ReadContinuously ) EPC_Import;

/*
   LIH_AvailableStimAndSample
      Returns the number of samples available for one Adc channel.
      "StillRunning" will be true, if acquisition is still running, and false
      otherwise (e.g. if acquisition was stopped with a call to LIH_Halt).
*/
EPC_INT32 EPC_Calling LIH_AvailableStimAndSample( EPC_BOOLEAN *StillRunning ) EPC_Import;

/*
   LIH_ReadStimAndSample
      - "AdcSamplesPerChannel" is the number of AD values to read out from
        the FIFO for each acquired AdcChannel.
      - "DoHalt": if = 1, tells the driver to stop acquisition.
      - "InData" is a pointer to an array of ADDRESSes, each element being
        the address of one AD-buffer to which the data are copied to.
        There must be least "AdcChannelNumber" addresses in that array, as
        issued in the call to LIH_StartStimAndSample.
*/
void EPC_Calling LIH_ReadStimAndSample(
           EPC_INT32 AdcSamplesPerChannel,
           EPC_BOOLEAN DoHalt,
           EPC_ADDR32 InData ) EPC_Import;

/*
   LIH_ReadStimAndSample_ml
      - Equivalent to LIH_ReadStimAndSample_ml
        Helper function for languages not supporting vectors, i.e. array of ADDRESSes,
        such as MatLab.
      - InData vector defined as the equivaluent array elements.
*/
void EPC_Calling LIH_ReadStimAndSample_ml(
           EPC_INT32 AdcSamplesPerChannel,
           EPC_BOOLEAN DoHalt,
           EPC_ADDR32 InData0,
           EPC_ADDR32 InData1,
           EPC_ADDR32 InData2,
           EPC_ADDR32 InData3,
           EPC_ADDR32 InData4,
           EPC_ADDR32 InData5,
           EPC_ADDR32 InData6,
           EPC_ADDR32 InData7 ) EPC_Import;

/*
   LIH_AppendToFIFO
      The function LIH_AppendToFIFO should never append mode data to the
      DAC FIFO than ADC samples previously read out from the ADC FIFO by the
      function LIH_ReadStimAndSample.
      - "DacSamplesPerChannel" is the number of DA values to append to the
        DAC FIFO for each used DacChannel.
        "LIH_EnableDacOutput" must have been set in "AcquisitionMode", when
        LIH_StartStimAndSample was issued.
      - "SetStimEnd": if = 1, tells the driver, that the present DAC templates
        are the last to be appended. For the reason see LIH_StartStimAndSample.
      - "OutData" is a pointer to an array of ADDRESSes, each element being
        the address of one DA-template.
        There must be least "DacChannelNumber" templates in that array, as
        issued in the call to LIH_StartStimAndSample.
      - Never append more data than LIH_AvailableStimAndSample had reported.
*/
EPC_BOOLEAN EPC_Calling LIH_AppendToFIFO(
           EPC_INT32 DacSamplesPerChannel,
           EPC_BOOLEAN SetStimEnd,
           EPC_ADDR32 OutData ) EPC_Import;

/*
   LIH_AppendToFIFO_ml
      - Equivalent to LIH_AppendToFIFO_ml
        Helper function for languages not supporting vectors, i.e. array of ADDRESSes,
        such as MatLab.
      - OutData vector defined as the equivaluent array elements.
*/
EPC_BOOLEAN EPC_Calling LIH_AppendToFIFO_ml(
           EPC_INT32 DacSamplesPerChannel,
           EPC_BOOLEAN SetStimEnd,
           EPC_ADDR32 OutData0,
           EPC_ADDR32 OutData1,
           EPC_ADDR32 OutData2,
           EPC_ADDR32 OutData3 ) EPC_Import;

// LIH_Halt
// Stops acquisition, if the interface is acquiring.
void EPC_Calling LIH_Halt( void ) EPC_Import;

// LIH_ForceHalt
// Issues a halt command under any acquisition state.
// LIH_Halt is the preferred command to stop acquiring. 
// LIH_ForceHalt consumes time for the forced USB communication,
// yet it guarantees resetting the acquisition mode. It may be
// the preferable command, when an error condition did occur.
void EPC_Calling LIH_ForceHalt( void ) EPC_Import;

// LIH_ReadAdc
// Reads the given AD input channel.
EPC_INT32 EPC_Calling LIH_ReadAdc( EPC_INT32 Channel ) EPC_Import;

// LIH_ReadDigital
// Reads the digital input port.
EPC_SET16 EPC_Calling LIH_ReadDigital( void  ) EPC_Import;

// LIH_ReadAll
// Returns the values of all 8 or 16 AD input channels plus the
// status of the digital input port.
// "AdcVoltages" is a pointer to an array of "LIH_MaxAdcChannels" LONGREALs.
// "DigitalPort" is the pointer to a buffer into which the 16 bits of the
// 2 digital input channel are stored.
// Returns true if successful, false if an error occurred.
EPC_BOOLEAN EPC_Calling LIH_ReadAll(
            EPC_ADDR32 AdcVoltages,
            EPC_SET16 *DigitalPort,
            EPC_LONGREAL Interval ) EPC_Import;

// LIH_SetDac
// Sets the specified DA channel to the given value.
void EPC_Calling LIH_SetDac( EPC_INT32 Channel, EPC_INT32 Value ) EPC_Import;

// LIH_GetDigitalOutState
// Returns the bit pattern of the digital user output port.
// Required to get the port state, when multiple devices are using
// the digital user output port. E.g., EPC9, EPC8, or TIB14.
// The user may want to use the bits which are not reserved to drive
// theattaaached device. In such a case, the user has to obtain the
// bit pattern via LIH_GetDigitalOutState, than change those bits he
// wants to change, then send the resulting bit pattern to the digital
// user output port. That way the mentioned devices are not affected.
EPC_SET16 EPC_Calling LIH_GetDigitalOutState( void ) EPC_Import;

// LIH_SetDigital
// Sets the status of the digital user port. It knows how to handle
// concurrent support for TIB14, EPC8, and the remaining user bits
// of the digital user port.
void EPC_Calling LIH_SetDigital( EPC_SET16 Value ) EPC_Import;

// LIH_VoltsToDacUnits
// Returns the integer value needed to output the given "Volts" value
// on the specified DA channel.
// The Volts value will be updated to reflect the exact voltage output
// value corresponding to the returned DA units.
EPC_INT32 EPC_Calling LIH_VoltsToDacUnits(
            EPC_INT32 DacChannel,
            EPC_LONGREAL *Volts ) EPC_Import;

// LIH_AdcUnitsToVolts
// Returns the voltage value corresponding to given "AdcUnits" value
// from the specified AD channel.
EPC_LONGREAL EPC_Calling LIH_AdcUnitsToVolts(
            EPC_INT32 AdcChannel,
            EPC_INT32 AdcUnits ) EPC_Import;

// LIH_CheckSampleInterval
// Returns the nearest sampling interval which the interface can support.
EPC_LONGREAL EPC_Calling LIH_CheckSampleInterval( EPC_LONGREAL SamplingInterval ) EPC_Import;

// LIH_Status
// Returns the present status of the interface.
// Definition of LIH_StatusType see above.
EPC_INT32 EPC_Calling LIH_Status( void ) EPC_Import;

// LIH_SetInputRange
// Selects the input range for the given AD channel, and returns the
// input range activated.
// Only specific interfaces support that feature, presently it is the ITC-18.
// Returns the Range actually set.
// Definition of LIH_AdcInputRangeType see above.
EPC_INT32 EPC_Calling LIH_SetInputRange(
            EPC_INT32 AdcChannel,
            EPC_INT32 InputRange ) EPC_Import;

// LIH_GetBoardType
// Returns the present interface type.
// Definition of LIH_BoardType see above.
EPC_INT32 EPC_Calling LIH_GetBoardType( void ) EPC_Import;

// LIH_GetErrorText
// Returns the error as plain text, when an error occurred.
void EPC_Calling LIH_GetErrorText( EPC_ADDR32 Text ) EPC_Import;

// LIH_GetBoardInfo
// Returns information about the selected interface configuration.
// The information is only correct after having successfully initialized
// the interface.
void EPC_Calling LIH_GetBoardInfo(
            EPC_LONGREAL *SecPerTick,
            EPC_LONGREAL *MinSamplingTime,
            EPC_LONGREAL *MaxSamplingTime,
            EPC_INT32  *FIFOLength,
            EPC_INT32  *NumberOfDacs,
            EPC_INT32  *NumberOfAdcs ) EPC_Import;


// TIB14_Present
// Returns true if the TIB14 has been detected connected to the
// digital input port, false otherwise.
EPC_BOOLEAN EPC_Calling TIB14_Present( void ) EPC_Import;

// TIB14_Initialize
// Initialized the TIB14.
// Returns true if successful, false if an error occurred.
EPC_BOOLEAN EPC_Calling TIB14_Initialize( void ) EPC_Import;


// PSA12_Initialize
// Establishes a connection to the PSA12 sound generator.
// Returns true if successful, false if an error occurred.
EPC_BOOLEAN EPC_Calling PSA12_Initialize( EPC_ADDR32 ErrorMessage ) EPC_Import;

// PSA12_Shutdown
// Shuts down the PSA12 and disconnects from the driver.
void EPC_Calling PSA12_Shutdown( void ) EPC_Import;

// PSA12_IsOpen
// Returns true, if the connection to the PSA12 has been
// established, false otherwise.
EPC_BOOLEAN EPC_Calling PSA12_IsOpen( void ) EPC_Import;

// PSA12_SetTone
// Outputs the given tone from the PSA12.
// Returns true on success, false otherwise.
EPC_BOOLEAN EPC_Calling PSA12_SetTone(
             EPC_LONGREAL Frequency,
             EPC_LONGREAL Amplitude,
             EPC_ADDR32 ErrorMessage ) EPC_Import;

#ifdef __cplusplus
}
#endif

#endif

