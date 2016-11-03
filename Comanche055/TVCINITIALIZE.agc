### FILE="Main.annotation"
## Copyright:	Public domain.
## Filename:	TVCINITIALIZE.agc
## Purpose:	Part of the source code for Colossus 2A, AKA Comanche 055.
##		It is part of the source code for the Command Module's (CM)
##		Apollo Guidance Computer (AGC), for Apollo 11.
## Assembler:	yaYUL
## Contact:	Jim Lawton <jim.lawton@gmail.com>.
## Website:	www.ibiblio.org/apollo.
## Pages:	936-944
## Mod history:	2009-05-11 JVL	Adapted from the Colossus249/ file
##				of the same name, using Comanche055 page
##				images.
##		2009-05-20 RSB	Corrections:  +80 -> +8D, added 4 missing 
##				lines in TVCINIT1, changed the capitalization
##				of a couple of the "Page N" comments, 
##				corrected a couple of lines in LOADCOEFF.
##		2009-05-22 RSB	In LOADCOEF, DXCH N10 +14D corrected to
##				TS N10 +14D.  Also, various comment-marks
##				were added to comments following this
##				change.
##		2010-08-28 JL	Fixed indentation.
##
## This source code has been transcribed or otherwise adapted from digitized
## images of a hardcopy from the MIT Museum.  The digitization was performed
## by Paul Fjeld, and arranged for by Deborah Douglas of the Museum.  Many
## thanks to both.  The images (with suitable reduction in storage size and
## consequent reduction in image quality as well) are available online at
## www.ibiblio.org/apollo.  If for some reason you find that the images are
## illegible, contact me at info@sandroid.org about getting access to the
## (much) higher-quality images which Paul actually created.
##
## Notations on the hardcopy document read, in part:
##
##    Assemble revision 055 of AGC program Comanche by NASA
##    2021113-051.  10:28 APR. 1, 1969 
##
##    This AGC program shall also be referred to as
##            Colossus 2A

## Page 937
# NAME		TVCDAPON (TVC DAP INITIALIZATION AND STARTUP CALL)
# LOG SECTION...TVCINITIALIZE			SUBROUTINE...DAPCSM
# MODIFIED BY SCHLUNDT				21 OCTOBER 1968
# FUNCTIONAL DESCRIPTION
#	PERFORMS TVCDAP INITIALIZATION (GAINS, TIMING PARAMETERS, FILTER VARIABLES, ETC.)
#	COMPUTES STEERING (S40.8) GAIN KPRIMEDT, AND ZEROES PASTDELV,+1 VARIABLE
#	MAKES INITIALIZATION CALL TO "NEEDLER" FOR TVC DAP NEEDLES-SETUP
#	PERFORMS INITIALIZATION FOR ROLL DAP
#	CALLS TVCEXECUTIVE AT TVCEXEC, VIA WAITLIST
#	CALLS TVCDAP CDU-RATE INITIALIZATION PKG AT DAPINIT  VIA T5
#	PROVIDES FOR LOADING OF LOW-BANDWIDTH COEFFS AND GAINS AT SWICHOVR
# CALLING SEQUENCE - T5LOC=2CADR(TVCDAPON,EBANK=BZERO), T5=.6SECT5
#	IN PARTICULAR, CALLED BY "DOTVCON" IN P40
#	MRCLEAN AND TVCINIT4 ARE POSSIBLE TVC-RESTART ENTRY POINTS
# NORMAL EXIT MODE
#	TCF RESUME
# SUBROUTINES CALLED
#	NEEDLER, MASSPROP
# ALARM OR ABORT EXIT MODES
#	NONE
# ERASABLE INITIALIZATION REQUIRED
#	CSMMASS, LEMMASS, DAPDATR1 (FOR MASSPROP SUBROUTINE)
#	TVC PAD LOADS (SEE EBANK6 IN ERASABLE ASSIGNMENTS)
#	PACTOFF, YACTOFF, CDUX
#	TVCPHASE AND THE T5 BITS OF FLAGWRD6 (SET AT DOTVCON IN P40)
# OUTPUT
#	ALL TVC AND ROLL DAP ERASABLES, FLAGWRD6 (BITS 13,14), T5, WAITLIST
# DEBRIS
#	NONE

		COUNT*	$$/INIT
		BANK	17
		SETLOC	DAPS7
		BANK
		
		EBANK=	BZERO
		
TVCDAPON	LXCH	BANKRUPT	# T5 RUPT ARRIVAL (CALL BY DOTVCON - P40)
		EXTEND			# SAVE Q REQUIRED IN RESTART (MRCLEAN AND
		QXCH	QRUPT		#	TVCINIT4 ARE ENTRIES)
MRCLEAN		CAF	NZERO		# NUMBER TO ZERO, LESS ONE  (MUST BE ODD)
					#	TVC RESTARTS ENTER HERE  (NEW BANK)
 +1		CCS	A
		TS	CNTR
		CAF	ZERO
		TS	L
		INDEX	CNTR
		DXCH	OMEGAYC		# FIRST (LAST) TWO LOCATIONS
		CCS	CNTR
		TCF	MRCLEAN +1
## Page 938
		EXTEND			# SET UP ANOTHER T5 RUPT TO CONTINUE
		DCA	INITLOC2	#	INITIALIZATION AT TVCINIT1
		DXCH	T5LOC		# THE PHSCHK2 ENTRY (REDOTVC) AT TVCDAPON
		CAF	POSMAX		#	+3 IS IN ANOTHER BANK.  MUST RESET
		TS	TIME5		#	BBCON TOO (FULL 2CADR), FOR THAT
ENDMRC		TCF	RESUME		#	ENTRY.

TVCINIT1	LXCH	BANKRUPT
		EXTEND
		QXCH	QRUPT
		
		TC	IBNKCALL	# UPDATE IXX, IAVG/TLX FOR DAP GAINS (R03
		CADR	MASSPROP	#	OR NOUNS 46 AND 47 MUST BE CORRECT)
		
		CAE	EMDOT		# SPS FLOW RATE, SCALED B+3 KG/CS
		EXTEND
		MP	ONETHOU
		TS	TENMDOT		# 10-SEC MASS LOSS B+16 KG
		COM
		AD	CSMMASS
		TS	MASSTMP		# DECREMENT FOR FIRST 10 SEC OF BURN
		
		CAE	DAPDATR1	# CHECK LEM-ON/OFF
		MASK	BIT14
		CCS	A
		CAF	BIT1		# LEM-ON (BIT1)
		TS	CNTR		# LEM-OFF (ZERO)
		
		INDEX	CNTR		# LOAD THE FILTER COEFFICIENTS
		CAF	CSMCFADR
		TS	COEFFADR
		TC	LOADCOEF
		
		INDEX	CNTR		# PICK UP LM-OFF,-ON KTLX/I
		CAE	EKTLX/I		# SCALED AT 1/(8 ASCREV) OF ACTUAL VALUE
		TS	KTLX/I
		
		TCR	S40.15		# COMPUTE 1/CONACC, VARK
		
TVCINIT2	CS	CNTR		# PICK LM-OFF,-ON VALUE FOR FILTER PERIOD
		INDEX	A		# DETERMINATION:
		CAF	BIT2		# 	BIT2 FOR CSM ONLY 40MS FILTER
		TS	KPRIMEDT	# 	BIT3 FOR CSM/LM 80MS FILTER
		
		COM			# PREPARE T5TVCDT
		AD	POSMAX
		AD	BIT1
		TS	T5TVCDT
		
		CS	BIT15		# RESET SWTOVER FLAG
## Page 939		
		MASK	FLAGWRD9
		TS	FLAGWRD9
		
		INDEX	CNTR		# PICK UP LEM-OFF,-ON KPRIME
		CAE	EKPRIME		#	SCALED (100 PI)/16
		EXTEND
		MP	KPRIMEDT	# (TVCDT/2, SC.AT B+14 CS)
		LXCH	A		#	SC.AT PI/8	(DIMENSIONLESS)
		DXCH	KPRIMEDT
		
		INDEX	CNTR		# PICK UP LEM-OFF,-ON REPFRAC
		CAE	EREPFRAC
		TS	REPFRAC

		INDEX	CNTR		# PICK UP ONE-SHOT CORRECTION TIME
		CAF	TCORR
		TS	CNTR

		CAF	NEGONE		# PREVENT STROKE TEST UNTIL CALLED
		TS	STRKTIME
		
		CAF	NINETEEN	# SET VCNTR FOR VARIABLE-GAIN UPDATES IN
		TS	VCNTR		#	10 SECONDS (TVCEXEC 1/2 SEC RATE)
		TS	V97VCNTR	# FOR ENGFAIL (R41) LOGIC
		
TVCINIT3	CAE	PACTOFF		# TRIM VALUES TO TRIM-TRACKERS, OUTPUT
		TS	PDELOFF		#	TRACKERS, OFFSET-UPDATES, AND
		TS	PCMD		#	OFFSET-TRACKER FILTERS
		TS	DELPBAR		#	NOTE, LO-ORDER DELOFF,DELBAR ZEROED
		
		CAE	YACTOFF
		TS	YDELOFF
		TS	YCMD
		TS	DELYBAR

ATTINIT		CAE	DAPDATR1	# ATTITUDE-ERROR INITIALIZATION LOGIC
		MASK	BIT13		#	TEST FOR CSM OR CSM/LM
		EXTEND
		BZF	NEEDLEIN	#	BYPASS INITIALIZATION FOR CSM/LM

		CAF	BIT1		#	SET UP TEMPORARY COUNTER
 +5		TS	TTMP1

		INDEX	TTMP1
		CA	ERRBTMP		# ERRBTMP CONTAINS RCS ATTITUDE ERRORS
		EXTEND			#	ERRORY & ERRORZ (P40 AT DOTVCON)
		MP	1/ATTLIM	# .007325(ERROR) = 0 IF ERROR < 1.5 DEG
		EXTEND
		BZF	+8D		#	|ERROR| LESS THAN 1.5 DEG
		EXTEND
## Page 940
		BZMF	+3		#	|ERROR| > 1.5 DEG, AND NEG
		CA	ATTLIM		#	|ERROR| > 1.5 DEG, AND POS
		TCF	+2
 +3		CS	ATTLIM
 +2		INDEX	TTMP1
		TS	ERRBTMP
 +8		CCS 	TTMP1		#	TEST TEMPORARY COUNTER
		TCF	ATTINIT +5	#	BACK TO REPEAT FOR PITCH ERROR

		CA	ERRBTMP		# ERROS ESTABLISHED AND LIMITED
		TS	PERRB
		CA	ERRBTMP +1
		TS	YERRB

NEEDLEIN	CS	RCSFLAGS	# SET BIT 3 FOR INITIALIZATION PASS AND GO
		MASK	BIT3		# 	TO NEEDLER.  WILL CLEAR FOR TVC DAP
		ADS	RCSFLAGS	# 	(RETURNS AFTER CADR)
		TC	IBNKCALL
		CADR	NEEDLER
		
TVCINIT4	CAF	ZERO		# SET TVCPHASE TO INDICATE TVCDAPON-THRU-
		TS	TVCPHASE	#	NEEDLEIN INITIALIZATION FINISHED.
					#	(POSSIBLE TVC-RESTART ENTRY)
					
		CAE	CDUX		# PREPARE ROLL DAP
		TS	OGANOW

		CAF	BIT13		# IF ENGINE IS ALREADY OFF, ENGINOFF HAS
		EXTEND			#	ALREADY ESTABLISHED THE POST-BURN
		RAND	DSALMOUT	#	CSMMASS (MASSBACK DOES IT).  DON'T
		EXTEND			# 	TOUCH CSMMASS.  IF ENGINE IS ON,
		BZF	+3		#	THEN IT'S OK TO DO THE COPYCYCLE
					#	EVEN BURNS LESS THAN 0.4 SEC ARE AOK
					
		CAE	MASSTMP		# COPYCYCLE
		TS	CSMMASS
		
 +3		CAF	.5SEC		# CALL TVCEXECUTIVE (ROLLDAP CALL, ETC)
		TC	WAITLIST
		EBANK=	BZERO
		2CADR	TVCEXEC
		
		EXTEND			# CALL FOR DAPINIT
		DCA	DAPINIT5
		DXCH	T5LOC
		CAE	T5TVCDT		# (ALLOW TIME FOR RESTART COMPUTATIONS)
		TS	TIME5
## Page 941
ENDTVCIN	TCF	RESUME

PRESWTCH	TCR	SWICHOVR	# ENTRY FROM V46

		TC	POSTJUMP	# THIS PROVIDES AN EXIT FROM SWITCH-OVER
		CADR	PINBRNCH	#	(PINBRNCH DOES A RELINT)

SWICHOVR	INHINT
		CA	TVCPHASE	# SAVE TVCPHASE
		TS	PHASETMP
		CS	BIT2		# SET TVCPHASE = -2 (INDICATES SWITCH-OVER
		TS	TVCPHASE	#	TO RESTART LOGIC)

 +5		EXTEND			# SAVE Q FOR RETURN (RESTART ENTRY POINT,
		QXCH	RTRNLOC		#	TVCPHASE AND PHASETMP ALREADY SET)

		CAF	NZEROJR		# ZEROING LOOP FOR FILTER STORAGE LOCS
 +8		TS	CNTRTMP

MCLEANJR	CA	ZERO
		TS	L
		INDEX	CNTRTMP
		DXCH	PTMP1 -1
		CCS	CNTRTMP
		CCS	A
		TCF	SWICHOVR +8D
		
		CS	FLAGWRD9	# SET SWITCHOVER FLAG FOR DOWNLINK
		MASK	BIT15
		ADS	FLAGWRD9

		CAE	EKTLX/I +2	# LOW BANDWIDTH GAINS 	- DAP
		TS	KTLX/I
		TCR	S40.15 	+7
		
		CAF	FKPRIMDT	#			- STEERING
		TS	KPRIMEDT
		
		CAF	FREPFRAC	#			- TMC LOOP
		TS	REPFRAC

		EXTEND			# UPDATE TRIM ESTIMATES
		DCA	DELPBAR
		DXCH	PDELOFF
		EXTEND
		DCA	DELYBAR
		DXCH	YDELOFF
		
		CA	LBCFADR
## Page 942
		TS	COEFFADR
		TC	LOADCOEF

		CAE	PHASETMP	# RESTORE TVCPHASE
		TS	TVCPHASE

		TC	RTRNLOC		# BACK TO PRESWTCH OR TVCRESTARTS

LOADCOEF	EXTEND			# LOAD DAP FILTER COEFFICIENTS
		INDEX	COEFFADR	#   FROM: ERASABLE FOR CSM/LM HB
		DCA	0		#         FIXED    FOR CSM/LM LB
		DXCH	N10		#         FIXED    FOR CSM

		EXTEND			# NOTE: FOR CSM/LM, NORMAL COEFFICIENT
		INDEX	COEFFADR	# LOAD WILL BE HIGH BANDWIDTH PAD LOAD
		DCA	2		# ERASABLES. DURING CSM/LM SWITCHOVER, 
		DXCH	N10 	+2	# THIS LOGIC IS USED TO LOAD LOW BANDWIDTH
					# COEFFICIENTS FROM FIXED MEMORY.

		EXTEND
		INDEX	COEFFADR
		DCA	4
		DXCH	N10 	+4

		EXTEND
		INDEX	COEFFADR
		DCA	6
		DXCH	N10 	+6

		EXTEND
		INDEX	COEFFADR
		DCA	8D
		DXCH	N10 	+8D

		EXTEND
		INDEX	COEFFADR
		DCA	10D
		DXCH	N10 	+10D

		EXTEND
		INDEX	COEFFADR
		DCA	12D
		DXCH	N10 	+12D

		INDEX	COEFFADR
		CA	14D
		TS	N10 	+14D

		TC	Q
## Page 943
S40.15		CAE	IXX		# GAIN COMPUTATIONS (1/CONACC, VARK)
		EXTEND			# ENTERED FROM TVCINITIALIZE AND TVCEXEC
		MP	2PI/M		#	2PI/M SCALED 1/(B+8 N M)
		DDOUBL			#	IXX   SCALED B+20 KG-MSQ
		DDOUBL
		DDOUBL
		TS	1/CONACC	#	      SCALED B+9 SEC-SQ/REV

 +7		CAE	KTLX/I		# ENTRY FROM CSM/LM V46 SWITCH-OVER
		EXTEND			#            SCALED (B+3 ASCREV)  1/SECSQ
		MP	IAVG/TLX	#            SCALED B+2 SECSQ
		DDOUBL
		DDOUBL
		TS	VARK		#            SCALED (B+3 ASCREV)
		TC	Q

CSMN10		DEC	.99999		# N10	CSM ONLY FILTER COEFFICIENTS
		DEC	-.2549		# N11/2
		DEC	.0588		# N12
		DEC	-.7620		# D11/2
		DEC	.7450		# D12

		DEC	.99999		# N20
		DEC	-.4852		# N21/2
		DEC	0		# N22
		DEC	-.2692		# D22/2
		DEC	0		# D22

LBN10		DEC	+.99999		# N10	LOW BANDWIDTH FILTER COEFFICIENTS
		DEC	-.3285		# N11/2
		DEC	-.3301		#N12
		DEC	-.9101		#D11/2
		DEC	+.8460		#D12

		DEC	+.03125		#N20
		DEC	0		#N21/2
		DEC	0		#N22
		DEC	-.9101		#D21/2
		DEC	+.8460		#D22

		DEC	+.50000		#N30
		DEC	-.47115		#N31/2
		DEC	+.4749		#N32
		DEC	-.9558		#D31/2
		DEC	+.9372		#D32

CSMCFADR	GENADR	CSMN10		# CSM ONLY COEFFICIENTS ADDRESS
HBCFADR		GENADR	HBN10		# HIGH BANDWIDTH COEFFICIENTS ADDRESS
## Page 944
LBCFADR		GENADR	LBN10		# LOW BANDWIDTH COEFFICIENTS ADDRESS

NZERO		DEC	51		# MUST BE ODD FOR MRCLEAN
NZEROJR		DEC	23		# MUST BE ODD FOR MCLEANJR

ATTLIM		DEC	0.00833		# INITIAL ATTITUDE EROR LIMIT (1.5 DEG)
1/ATTLIM	DEC	0.007325	# .007325(ERROR) = 0 IF ERROR < 1.5 DEG

TCORR		OCT	00005		# CSM
 +1		OCT	00000		# CSM/LM (HB,LB)

FKPRIMDT	DEC	.0102		# CSM/LM (LB), (.05 X .08) SCALED AT PI/8
FREPFRAC	DEC	.0375 B-2	# CSM/LM (LB), 0.0375 SCALED AT B+2

NINETEEN	=	VD1
2PI/M		DEC	.00331017 B+8	# 2PI/M, SCALED AT 1/(B+8 N-M)

ONETHOU		DEC	1000 B-13	# KG/CS B3 TO KG/10SEC B16 CONVERSION

		EBANK=	BZERO
DAPINIT5	2CADR	DAPINIT

		EBANK=	BZERO
INITLOC2	2CADR	TVCINIT1
