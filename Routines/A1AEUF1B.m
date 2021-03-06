A1AEUF1B ;VEN/LGC/JLI - UNIT TESTS FOR A1AEF1 CONT ; 10/20/14 7:23am
 ;;2.4;PATCH MODULE;; SEP 24, 2014
 ;
 ;
START I $T(^%ut)="" W !,"*** UNIT TEST NOT INSTALLED ***" Q
 N A1AEFAIL S A1AEFAIL=0
 D EN^%ut($T(+0),1)
 Q
 ;
STARTUP S A1AEFAIL=0 ; KILLED IN SHUTDOWN
 L +^XPD(9.6):1 I '$T D  Q
 . S A1AEFAIL=1
 . W !,"Unable to obtain lock on BUILD [#9.6] file"
 . W !," Unable to perform testing."
 ;
 L +^A1AE(11005):1 I '$T D  Q
 . S A1AEFAIL=1
 . W !,"Unable to obtain lock on DHCP PATCHES  [#11005] file"
 . W !," Unable to perform testing."
 ;
 ; X may be 0 if none to delete = normal circumstance
 ; X = 1 if previous testing incomplete = ok too
 I '$G(A1AEFAIL) S X=$$DLTSBLDS
 I '$G(A1AEFAIL) S X=$$DELTBLDS
 Q
 ;
SHUTDOWN S X=$$PTC4KID5 I 'X D
 . W !,"Unable to clear test builds"
 . W !," It may be necessary to delete test"
 . W !," build entries in BUILD [#9.6] file"
 . W !," manually [A1AEXTST*1*n].",!
 L -^XPD(9.6):1
 ; ZEXCEPT: A1AEFAIL - defined in STARTUP
 K A1AEFAIL
 Q
 ;
 ; Testing 
 ;   PTC4KIDS^A1AEF1(BUILD,.BARR)
UTP7 I '$G(A1AEFAIL) D
 . S X=$$SETUP1 I 'X D  Q
 .. D FAIL^%ut("Unable to build array of BUILD names")
 . S X=$$SETUP2 I 'X D  Q
 .. D FAIL^%ut("Unable to complete entry of TEST builds")
 . S X=$$SETUP3 I 'X D  Q
 .. D FAIL^%ut("Unable to complete build interdependencies")
 N SEQ,SEQ1,SEQ2
 I '$G(A1AEFAIL) D
 . S X=$$PTC4KID1 I 'X D  Q
 .. D FAIL^%ut("Unable to obtain 10 builds for each seqence")
 . S X=$$PTC4KID2 I 'X D  Q
 .. D FAIL^%ut("Unable to complete additional build dependencies")
 . S X=$$PTC4KID3 I 'X D  Q
 .. D FAIL^%ut("Unable to add new REQB to new build entries")
 . S X=$$PTC4KID4 I 'X D  Q
 .. D FAIL^%ut("Unable to build testing array")
 ;
 I '$G(A1AEFAIL) D PTC4KIDS^A1AEF1(BUILD(20),.POO,"") D
 . D CHKEQ^%ut(1,X,"Testing PTC4KIDS Builds for sequence FAILED!")
 Q
 ;
 ;
 ; Hop over to DHCP PATCHES and find 10 each of
 ;  VISTA and OSEHRA stream
 ; Pass on patches with n.0 version
PTC4KID1() N PD,NODE S NODE=$NA(^A1AE(11005))
 F  S NODE=$Q(@NODE) Q:NODE'["^A1AE(11005,"  D  I $G(SEQ1)>10,$G(SEQ2)>10 Q
 . I $QS(NODE,3)=0  D
 .. I $P(@NODE,"^",20)=1 D:$G(SEQ1)<10
 ... I $P($P($G(^A1AE(11005,$QS(NODE,2),0)),"^"),"*",2)'?.NP Q
 ... S SEQ1=$G(SEQ1)+1,SEQ1(SEQ1)=$QS(NODE,2)
 .. I $P(@NODE,"^",20)=10001 D:$G(SEQ2)<10
 ... I $P($P($G(^A1AE(11005,$QS(NODE,2),0)),"^"),"*",2)'?.NP Q
 ... S SEQ2=$G(SEQ2)+1,SEQ2(SEQ2)=$QS(NODE,2)
 I $G(SEQ1)=10,$G(SEQ2)=10 Q 1
 Q 0
 ;
 ; Make sure there are entries in BUILD [#9.6] file for each
 ;  of the collected patches from 11005
 ; If any do not have corresponding BUILD entries, add them
 ;  now.  Also give each a REQB of A1AEXTST*1*1 so they may
 ;  be recognized later for deletion
PTC4KID2() S SEQ=0 F  S SEQ=$O(SEQ1(SEQ)) Q:'SEQ  D
 .  S PD=$P($G(^A1AE(11005,SEQ1(SEQ),0)),"^")
 .  I '$O(^XPD(9.6,"B",PD,0)) D
 ..;  W !,"ADDING SEQ1 ",PD
 ..  S X=$$LDBLD^A1AEUF1(PD)
 ..  I X S X=$$LDRBLD^A1AEUF1(X,BUILD(1))
 S SEQ=0 F  S SEQ=$O(SEQ2(SEQ)) Q:'SEQ  D
 .  S PD=$P($G(^A1AE(11005,SEQ2(SEQ),0)),"^")
 .  I '$O(^XPD(9.6,"B",PD,0)) D
 ..;  W !,"ADDING SEQ2 ",PD
 ..  S X=$$LDBLD^A1AEUF1(PD)
 ..  I X S X=$$LDRBLD^A1AEUF1(X,BUILD(1))
 Q X
 ; 
 ; Now add all builds as REQB of BUILD(29)=A1AEXTST*1*29
 ; Run through SEQ1 and SEQ2, get name of patch from 11005
 ;   and with each one add the corresponding entry in 9.6
 ;   as a REQB for BUILD(29)
PTC4KID3() N B29IEN S B29IEN=$O(^XPD(9.6,"B",BUILD(29),0)) Q:'B29IEN
 S SEQ=0 F  S SEQ=$O(SEQ1(SEQ)) Q:'SEQ  D
 . S PD=$P($G(^A1AE(11005,SEQ1(SEQ),0)),"^") Q:PD=""
 . S X=$$LDRBLD(B29IEN,PD)
 S SEQ=0 F  S SEQ=$O(SEQ2(SEQ)) Q:'SEQ  D
 . S PD=$P($G(^A1AE(11005,SEQ2(SEQ),0)),"^") Q:PD=""
 . S X=$$LDRBLD(B29IEN,PD)
 Q:X 1  Q 0
 ;
 ; Build POO array using REQB 
PTC4KID4() ;
 ; We must have PRIMARY set to continue
 ;  if none is set, temporarily set the 
 ;  site to FOIA VISTA as PRIMARY
 N UTOPIEN S UTOPIEN=$$UTPRIEN
 I 'UTOPIEN S $P(^A1AE(11007.1,1,0),U,2)=1 D
 . N DIK,DA
 . S DIK(1)=".02",DIK="^A1AE(11007.1,"
 . D ENALL2^DIK
 . D ENALL^DIK
 S X=1
 N POO D REQB^A1AEF1(BUILD(29),.POO)
 ; Filter out those of wrong stream
 D PTC4KIDS^A1AEF1(BUILD(29),.POO,"")
 ; Now see if remaining match POO array for 
 ;   this stream
 N PRIM S PRIM=$O(^A1AE(11007.1,"APRIM",1,0))
 Q:'PRIM 0
 N SEQA S SEQA=$S(PRIM=1:"SEQ1",PRIM=10001:"SEQ2",1:"")
 Q:SEQA="" 0
 S SEQ=0,X=1
 ; Check that all patches left in the SEQA array
 ;   belong to this site's PRIMARY stream.
 ;   If we find one of another stream, X will
 ;   be returned as 0.  Otherwise, X will say as 1
 F  S SEQ=$O(@SEQA@(SEQ)) Q:'SEQ  D  Q:'X
 . S PD=$P(^A1AE(11005,@SEQA@(SEQ),0),"^")
 . S:'$D(POO(PD)) X=0
 S $P(^A1AE(11007.1,1,0),U,2)=+$G(UTOPIEN) D
 . N X,DIK,DA
 . S DIK(1)=".02",DIK="^A1AE(11007.1,"
 . D ENALL2^DIK
 . D ENALL^DIK
 Q X
 ;
PTC4KID5() S X=$$DLTSBLDS
 S X=$$DELTBLDS
 K BUILD
 Q X
 ;
 ; Build an array of bogus BUILD NAMES
SETUP1() N I
 F I=1:1:30 S BUILD(I)="A1AEXTST*1*"_I
 Q:I=30 1  Q 0
 ;
 ; Load new builds into BUILD [#9.6] file
SETUP2() N X,I F I=1:1:30 S X=$$LDBLD(BUILD(I)) Q:'X  D
 . S BUILD(BUILD(I))=X
 Q:X 1  Q X
 ;
 ; Use test builds to build an interdependant
 ;   array of CONTAINERS, PREREQUISITES, and
 ;   MEMBERS
SETUP3() ; BUILD(10)
 ;   REQUIRED BUILD multiple entries
 ;      BUILD(1)-BUILD(5)
 F I=1:1:5 S X=$$LDRBLD(BUILD(BUILD(10)),BUILD(I)) Q:'X
 Q:'X X
 ;   MULTIPLE BUILD multiple entries
 ;      BUILD(6)-BUILD(10)
 F I=6:1:10 S X=$$LDMBLD(BUILD(BUILD(10)),BUILD(I)) Q:'X
 Q:'X X
 ;
 ; BUILD(11)
 ;   REQUIRED BUILD multiple entries
 ;      BUILD(12)-BUILD(15)
 F I=12:1:15 S X=$$LDRBLD(BUILD(BUILD(11)),BUILD(I)) Q:'X
 Q:'X X
 ;   MULTIPLE BUILD multiple entries
 ;      BUILD(16)-BUILD(20)
 F I=16:1:20 S X=$$LDMBLD(BUILD(BUILD(11)),BUILD(I)) Q:'X
 Q:'X X
 ;
 ; BUILD(28)
 ;   REQUIRED BUILD multiple entries
 ;      BUILD(21)-BUILD(25)
 ;      BUILD(10)-BUILD(11)
 F I=21:1:25 S X=$$LDRBLD(BUILD(BUILD(28)),BUILD(I)) Q:'X
 Q:'X X
 F I=10:1:11 S X=$$LDRBLD(BUILD(BUILD(28)),BUILD(I)) Q:'X
 Q:'X X
 ;   MULTIPLE BUILD multiple entries
 ;      BUILD(26)-BUILD(27)
 F I=26,27 S X=$$LDMBLD(BUILD(BUILD(28)),BUILD(I)) Q:'X
 Q:'X X
 ;
 ; BUILD(29)
 ;   REQUIRED BUILD multiple entries
 ;      BUILD(28)
 S X=$$LDRBLD(BUILD(BUILD(29)),BUILD(28)) Q:'X
 Q:'X X
 ;   MULTIPLE BUILD multiple entries
 ;      BUILD(1)
 ;      BUILD(11)
 F I=1,11 S X=$$LDMBLD(BUILD(BUILD(29)),BUILD(I)) Q:'X
 Q:'X X
 ;
 ; BUILD(30)
 ;   REQUIRED BUILD multiple entries
 ;      BUILD(29)
 S X=$$LDRBLD(BUILD(BUILD(30)),BUILD(29)) Q:'X
 Q:'X X
 ;   MULTIPLE BUILD multiple entries
 ;      BUILD(28)
 S X=$$LDMBLD(BUILD(BUILD(29)),BUILD(28)) Q:'X
 Q:'X X
 Q 1
 ;
 ;Load new BUILD [#9.6] entry
 ;ENTER
 ;  BUILD   =  Build name
 ;RETURN
 ;  IEN of new BUILD entry OR 0_"^DIERR"
LDBLD(BUILD) ;
 Q:BUILD="" 0_"^No BUILD Name"
 N A1AEKI,A1AEPM,DIERR,FDA,FDAIEN
 S FDA(3,9.6,"?+1,",.01)=BUILD
 S FDA(3,9.6,"?+1,",2)=0
 S FDA(3,9.6,"?+1,",.02)=$$HTFM^XLFDT($H,1)
 S FDA(3,9.6,"?+1,",5)="n"
 D UPDATE^DIE("","FDA(3)","FDAIEN")
 I $D(DIERR) Q 0_"^DIERR"
 Q +FDAIEN(1)
 ;
 ; Load entry into MULTIPLE BUILD for this Container build
 ;ENTER
 ;   A1AEKI  = IEN OF Container Build
 ;   A1AEPM  = BUILD name of Member
 ;RETURN
 ;   IEN of new Member within Container BUILD
 ;     OR 0_"^DIERR"
LDMBLD(A1AEKI,MBUILD) ;
 Q:'A1AEKI 0_"^No Container BUILD IEN"
 Q:MBUILD="" 0_"^No Member BUILD Name"
 N FDA,DIERR,FDAIEN
 S FDA(3,9.63,"?+1,"_A1AEKI_",",.01)=MBUILD
 D UPDATE^DIE("","FDA(3)","FDAIEN")
 Q:$D(DIERR) 0_"^DIERR"
 Q +FDAIEN(1)
 ;
 ; Load entry into REQUIRED BUILD for this Container build
 ;ENTER
 ;   A1AEKI  = IEN OF Container Build
 ;   A1AEPM  = BUILD name of Member
 ;RETURN
 ;   IEN of new Member within Container BUILD
 ;     OR 0_"^DIERR"
LDRBLD(A1AEKI,RBUILD) ;
 Q:'A1AEKI 0_"^No Container BUILD IEN"
 Q:RBUILD="" 0_"^No Member BUILD Name"
 N FDA,DIERR,FDAIEN
 S FDA(3,9.611,"?+1,"_A1AEKI_",",.01)=RBUILD
 D UPDATE^DIE("","FDA(3)","FDAIEN")
 Q:$D(DIERR) 0_"^DIERR"
 Q +FDAIEN(1)
 ;
 ;
 ; Delete all test build entries
 ; RETURN
 ;  1 if no errors, 0 if deletion failed
 ;  Nothing to delete returns 1 for no errors
DELTBLDS() N DA,DIK,X,Y S X=1
 N NODE S NODE=$NA(^XPD(9.6,"B","A1AEXTST*1"))
 F  S NODE=$Q(@NODE) Q:NODE'["A1AEXTST*1"  D  Q:'X
 .  N DA,DIK,DIERR
 .  S DA=$QS(NODE,4)
 .  S DIK="^XPD(9.6,"
 .  D ^DIK
 .  S:$D(DIERR) X=0
 Q X
 ;
 ; Delete special builds
 ; Returns  1 = no errors, 0 = deletion failed
 ;  Nothing to delete returns 1 for no errors
DLTSBLDS() N DA,DIERR,X,Y S X=1
 N BIEN S BIEN=0
 F  S BIEN=$O(^XPD(9.6,BIEN)) Q:'BIEN  D
 .  S X=$O(^XPD(9.6,BIEN,"REQB","B","A1AEXTST*1*1",0)) Q:'X
 .  S DA=BIEN,DIK="^XPD(9.6," D ^DIK
 .  S:$D(DIERR) X=0
 Q X
 ;
 ; Function to return IEN of DHCP PATCH STREAM [#11007.1]
 ;   entry having PRIMARY? [#.02] field set
UTPRIEN() ;
 N A1AEI,UTPRIM S (A1AEI,UTPRIM)=0
 F  S A1AEI=$O(^A1AE(11007.1,A1AEI)) Q:'A1AEI  D
 . I $P(^A1AE(11007.1,A1AEI,0),U,2) S UTPRIM=A1AEI
 Q UTPRIM
 ;
UP(STR) Q $TR(STR,"abcdefghijklmnopqrstuvwxyz","ABCDEFGHIJKLMNOPQRSTUVWXYZ")
 ;
XTENT ;
 ;;UTP7;Testing collecting patches for KIDS
 Q
 ;
 ;
EOR ; end of routine A1AEUF1B
