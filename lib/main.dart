import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  runApp(const FlappyPiApp());
}

class FlappyPiApp extends StatelessWidget {
  const FlappyPiApp({super.key});
  @override
  Widget build(BuildContext context) => const MaterialApp(
        home: GameScreen(), debugShowCheckedModeBanner: false);
}

// ═══════════════════════════════════════════════════════════════════
//  STAŁE
// ═══════════════════════════════════════════════════════════════════
const double kW = 480, kH = 800;
const double kGravity = 1400, kJumpVel = -520;
const double kPipeW = 80, kPipeGap = 220, kPipeSpeedBase = 180;
const double kMinPipeH = 80, kGroundH = 60, kCoinR = 12, kPlayerR = 28;
const int kDailyBonus = 25, kTimedSecs = 60;

const String piDec =
    "14159265358979323846264338327950288419716939937510"
    "58209749445923078164062862089986280348253421170679"
    "82148086513282306647093844609550582231725359408128"
    "48111745028410270193852110555964462294895493038196"
    "44288109756659334461284756482337867831652712019091"
    "45648566923460348610454326648213393607260249141273"
    "72458700660631558817488152092096282925409171536436"
    "78925903600113305305488204665213841469519415116094";

// ═══════════════════════════════════════════════════════════════════
//  SKINY & DANE
// ═══════════════════════════════════════════════════════════════════
class PlayerSkin {
  final String id, name; final int price; final Color body, glow, pi;
  const PlayerSkin(this.id,this.name,this.price,this.body,this.glow,this.pi);
}
class PipeSkin {
  final String id, name; final int price; final Color body, dark, lite;
  const PipeSkin(this.id,this.name,this.price,this.body,this.dark,this.lite);
}
class Upgrade {
  final String id, name, desc; final int price, max;
  const Upgrade(this.id,this.name,this.desc,this.price,this.max);
}
class Achievement {
  final String id, name, desc, icon; final int req;
  const Achievement(this.id,this.name,this.desc,this.icon,this.req);
}

const playerSkins = [
  PlayerSkin('classic','Klasyczny',0, Color(0xFF323296),Color(0xFFFF9600),Color(0xFFFFD71E)),
  PlayerSkin('fire','Ogień',10,     Color(0xFF8C2814),Color(0xFFFF5000),Color(0xFFFFC832)),
  PlayerSkin('ice','Lód',10,        Color(0xFF1450A0),Color(0xFF64C8FF),Color(0xFFC8F0FF)),
  PlayerSkin('emerald','Szmaragd',15,Color(0xFF148C50),Color(0xFF32FF96),Color(0xFFC8FFC8)),
  PlayerSkin('galaxy','Galaktyka',25,Color(0xFF50148C),Color(0xFFB432FF),Color(0xFFDCB4FF)),
  PlayerSkin('gold','Złoty',40,     Color(0xFF8C640A),Color(0xFFFFDC00),Color(0xFFFFFFC8)),
  PlayerSkin('neon','Neon',30,      Color(0xFF0A0A0A),Color(0xFF00FFB4),Color(0xFF00FFC8)),
  PlayerSkin('cherry','Wiśnia',20,  Color(0xFFA0143C),Color(0xFFFF5078),Color(0xFFFFC8DC)),
];
const pipeSkins = [
  PipeSkin('green','Zielone',0,   Color(0xFF199664),Color(0xFF0F6441),Color(0xFF28C88C)),
  PipeSkin('red','Czerwone',8,    Color(0xFF961E1E),Color(0xFF640F0F),Color(0xFFDC3C3C)),
  PipeSkin('blue','Niebieskie',8, Color(0xFF1E50B4),Color(0xFF0F3278),Color(0xFF5096FF)),
  PipeSkin('purple','Fioletowe',12,Color(0xFF641EA0),Color(0xFF3C0F64),Color(0xFFB450FF)),
  PipeSkin('gold','Złote',20,     Color(0xFFA0820A),Color(0xFF645005),Color(0xFFFFD71E)),
  PipeSkin('cyan','Cyjan',15,     Color(0xFF0A96A0),Color(0xFF055A64),Color(0xFF32E6F0)),
];
const upgrades = [
  Upgrade('shield','Tarcza','1 życie zapasowe',80,1),
  Upgrade('slow_pipe','Wolne rury','Rury wolniejsze o 15%',60,3),
  Upgrade('wide_gap','Szeroka dziura','Dziura +30px szersza',100,3),
  Upgrade('magnet','Magnes','Przyciąga monety',120,1),
  Upgrade('double','x2 Monety','Podwójne monety',150,1),
];
const achievements = [
  Achievement('first_flight','Pierwszy lot','Przelec przez 1 rurę','🕊️',1),
  Achievement('mathematician','Matematyk π','Osiągnij wynik 31','🔢',31),
  Achievement('centurion','Centurion','Osiągnij wynik 100','💯',100),
  Achievement('millionaire','Milioner','Zbierz 1000 monet','💰',1000),
  Achievement('combo_king','Król Combo','Osiągnij combo x10','🔥',10),
  Achievement('survivor','Ocalały','Przeżyj z tarczą','🛡️',1),
  Achievement('speed_demon','Demon prędkości','Na π² przeżyj 20 rur','⚡',20),
  Achievement('shopaholic','Shopaholic','Kup 5 przedmiotów','🛒',5),
];

class Mission {
  final String id, name, desc; final int target, reward;
  int progress = 0; bool completed = false;
  Mission(this.id,this.name,this.desc,this.target,this.reward);
  double get pct => (progress/target).clamp(0,1);
}
List<Mission> freshMissions() => [
  Mission('pipes10','Przelec przez rury','Przelatuj przez 10 rur',10,15),
  Mission('coins20','Zbierz monety','Zbierz 20 monet w grach',20,20),
  Mission('score15','Wysoki wynik','Zdobądź 15 punktów',15,25),
  Mission('play3','Wróć do gry','Zagraj 3 razy',3,10),
];

// ═══════════════════════════════════════════════════════════════════
//  SAVE DATA
// ═══════════════════════════════════════════════════════════════════
class SaveData {
  int coins=0,highScore=0,highScoreTimed=0,totalCoinsEver=0,totalPipes=0,gamesPlayed=0,maxCombo=0,totalPurchases=0;
  String playerSkin='classic',pipeSkin='green',difficulty='π',lastBonusDate='',missionsDate='';
  bool muted=false;
  Map<String,int> upgradesMap={};
  Set<String> ownedPlayers={'classic'},ownedPipes={'green'},unlockedAchievements={};
  List<int> topScores=[];
  List<Mission> missions=freshMissions();

  String _today(){final n=DateTime.now();return '${n.year}-${n.month}-${n.day}';}
  bool get canClaimBonus=>lastBonusDate!=_today();
  void claimBonus(){coins+=kDailyBonus;lastBonusDate=_today();save();}
  int upgradeLevel(String id)=>upgradesMap[id]??0;

  void addTopScore(int s){
    topScores.add(s);
    topScores.sort((a,b)=>b.compareTo(a));
    if(topScores.length>5)topScores=topScores.sublist(0,5);
  }

  void fromJson(Map<String,dynamic> d){
    coins=d['coins']??0; highScore=d['highScore']??0; highScoreTimed=d['highScoreTimed']??0;
    playerSkin=d['playerSkin']??'classic'; pipeSkin=d['pipeSkin']??'green';
    difficulty=d['difficulty']??'π'; muted=d['muted']??false;
    upgradesMap=Map<String,int>.from(d['upgrades']??{});
    ownedPlayers=Set<String>.from(d['ownedPlayers']??['classic']);
    ownedPipes=Set<String>.from(d['ownedPipes']??['green']);
    unlockedAchievements=Set<String>.from(d['achievements']??[]);
    totalCoinsEver=d['totalCoinsEver']??0; totalPipes=d['totalPipes']??0;
    gamesPlayed=d['gamesPlayed']??0; maxCombo=d['maxCombo']??0;
    totalPurchases=d['totalPurchases']??0; lastBonusDate=d['lastBonusDate']??'';
    topScores=List<int>.from(d['topScores']??[]);
    missionsDate=d['missionsDate']??'';
    if(missionsDate==_today()){
      final md=List.from(d['missions']??[]);
      for(var i=0;i<missions.length&&i<md.length;i++){
        missions[i].progress=md[i]['progress']??0;
        missions[i].completed=md[i]['completed']??false;
      }
    } else { missions=freshMissions(); missionsDate=_today(); }
  }

  Map<String,dynamic> toJson()=>{
    'coins':coins,'highScore':highScore,'highScoreTimed':highScoreTimed,
    'playerSkin':playerSkin,'pipeSkin':pipeSkin,'difficulty':difficulty,'muted':muted,
    'upgrades':upgradesMap,'ownedPlayers':ownedPlayers.toList(),'ownedPipes':ownedPipes.toList(),
    'achievements':unlockedAchievements.toList(),'totalCoinsEver':totalCoinsEver,
    'totalPipes':totalPipes,'gamesPlayed':gamesPlayed,'maxCombo':maxCombo,
    'totalPurchases':totalPurchases,'lastBonusDate':lastBonusDate,'topScores':topScores,
    'missionsDate':missionsDate,
    'missions':missions.map((m)=>{'progress':m.progress,'completed':m.completed}).toList(),
  };

  Future<void> load()async{
    try{final p=await SharedPreferences.getInstance();final s=p.getString('flappypi');if(s!=null)fromJson(jsonDecode(s));}catch(_){}
  }
  Future<void> save()async{
    try{final p=await SharedPreferences.getInstance();await p.setString('flappypi',jsonEncode(toJson()));}catch(_){}
  }
}

// ═══════════════════════════════════════════════════════════════════
//  GAME OBJECTS
// ═══════════════════════════════════════════════════════════════════
class Player {
  double x,y,vel=0,angle=0,pulse=0,deathTimer=0,shieldAnim=0;
  bool alive=true,shielded=false,shieldHit=false;
  int combo=0; double comboTimer=0;
  PlayerSkin skin;
  Player(this.x,this.y,this.skin);
  void flap(){if(alive)vel=kJumpVel;}
  void addCombo(){combo++;comboTimer=3.0;}
  void update(double dt){
    pulse+=dt*3;
    if(shieldHit){shieldAnim+=dt;if(shieldAnim>0.5){shieldHit=false;shieldAnim=0;}}
    if(comboTimer>0){comboTimer-=dt;if(comboTimer<=0)combo=0;}
    if(!alive){deathTimer+=dt;vel=min(vel+kGravity*dt,600);y+=vel*dt;angle=max(angle-300*dt,-90);return;}
    vel=min(vel+kGravity*dt,600);y+=vel*dt;
    final tgt=-(vel/600)*30;angle+=(tgt-angle)*10*dt;angle=angle.clamp(-30,30);
  }
  Rect get rect{const r=kPlayerR*0.75;return Rect.fromCenter(center:Offset(x,y),width:r*2,height:r*2);}
}

class Pipe {
  double x,speed; final double topEnd,botTop; final String label; bool scored=false;
  Pipe(this.x,double gapC,this.speed,this.label,double eg)
    :topEnd=kH-(gapC+(kPipeGap+eg)/2),botTop=kH-(gapC-(kPipeGap+eg)/2);
  void update(double dt){x-=speed*dt;}
  bool get offScreen=>x+kPipeW<0;
  double get centerX=>x+kPipeW/2;
  Rect get topRect=>Rect.fromLTWH(x,0,kPipeW,max(0,topEnd));
  Rect get botRect=>Rect.fromLTWH(x,botTop,kPipeW,kH-botTop);
}

class Coin {
  double x,y,anim=0; bool collected=false;
  Coin(this.x,this.y);
  void update(double dt,double spd,{double? mx,double? my}){
    x-=spd*dt;anim+=dt*4;
    if(mx!=null&&my!=null){
      final dx=mx-x,dy=my-y,dist=sqrt(dx*dx+dy*dy);
      if(dist<180){final str=(1-dist/180)*600;x+=(dx/max(dist,1))*str*dt;y+=(dy/max(dist,1))*str*dt;}
    }
  }
  Rect get rect=>Rect.fromCenter(center:Offset(x,y),width:kCoinR*2,height:kCoinR*2);
}

class Particle {
  double x,y,vx,vy,life,maxLife,size; Color color;
  Particle(this.x,this.y,this.vx,this.vy,this.life,this.size,this.color):maxLife=life;
  bool get dead=>life<=0;
  void update(double dt){x+=vx*dt;y+=vy*dt;vy+=500*dt;life-=dt;}
}

class FloatText {
  double x,y,timer; final String txt; final Color color;
  FloatText(this.x,this.y,this.txt,{this.color=const Color(0xFFFFD71E)}):timer=1.2;
}

class Star {
  final double x,y,size,bright;
  Star(this.x,this.y,this.size,this.bright);
}

class Popup {
  String title,msg; double timer; Color color;
  Popup(this.title,this.msg,{this.timer=3.0,this.color=const Color(0xFFFFD71E)});
}

class BtnRect {
  final Rect rect; final VoidCallback action;
  BtnRect(this.rect,this.action);
  bool hit(Offset p)=>rect.contains(p);
}

enum GameMode{classic,timed,twoPlayer}
enum GS{menu,modeSelect,game,gameOver,shop,settings,achievements,leaderboard,missions}

// ═══════════════════════════════════════════════════════════════════
//  GAME ENGINE
// ═══════════════════════════════════════════════════════════════════
class GameEngine {
  final save=SaveData(); GS state=GS.menu; GameMode mode=GameMode.classic;
  double t=0; DateTime? _last; final _rng=Random();
  final stars=<Star>[]; final pipes=<Pipe>[]; final coins=<Coin>[];
  final floats=<FloatText>[]; final parts=<Particle>[]; final popups=<Popup>[];
  final shopBtns=<BtnRect>[]; final ui=<String,BtnRect>{};
  late Player p1; Player? p2;
  int score=0,score2=0,sessionCoins=0,piIdx=0,piCount=0;
  bool started=false; double pipeTimer=0,pipeSpeed=kPipeSpeedBase;
  double slowF=1,extraGap=0; bool hasMagnet=false,doubleCoins=false;
  double timedLeft=kTimedSecs.toDouble(); bool timedDone=false;
  String shopTab='player'; double shopScroll=0;
  Popup? bonusPopup; bool _loaded=false;

  GameEngine(){_init();}

  Future<void> _init()async{
    await save.load();
    for(var i=0;i<60;i++)stars.add(Star(_rng.nextDouble()*kW,_rng.nextDouble()*(kH-kGroundH),_rng.nextDouble()*2+1,_rng.nextDouble()*0.7+0.3));
    if(save.canClaimBonus)bonusPopup=Popup('🎁 Dzienny bonus!','+$kDailyBonus monet!',timer:6,color:const Color(0xFF32C864));
    _initGame(); _loaded=true;
  }

  void _initGame(){
    final skin=playerSkins.firstWhere((s)=>s.id==save.playerSkin,orElse:()=>playerSkins[0]);
    p1=Player(kW*0.25,kH*0.5,skin); p1.shielded=save.upgradeLevel('shield')>0;
    p2=mode==GameMode.twoPlayer?Player(kW*0.25,kH*0.3,playerSkins.firstWhere((s)=>s.id=='fire',orElse:()=>playerSkins[1])):null;
    pipes.clear();coins.clear();floats.clear();parts.clear();
    score=0;score2=0;sessionCoins=0;started=false;pipeTimer=0;piIdx=0;piCount=0;
    timedLeft=kTimedSecs.toDouble();timedDone=false;
    slowF=1-0.15*min(save.upgradeLevel('slow_pipe'),3);
    extraGap=30*min(save.upgradeLevel('wide_gap'),3).toDouble();
    hasMagnet=save.upgradeLevel('magnet')>0; doubleCoins=save.upgradeLevel('double')>0;
    final sm={'π/4':0.55,'π':1.0,'π²':1.5}[save.difficulty]!;
    pipeSpeed=kPipeSpeedBase*sm*slowF; _spawnPipe();
  }

  String _piNext(){
    piCount++;if(piCount==1){piIdx=3;return '3.14';}
    final c=piDec.substring(piIdx,min(piIdx+4,piDec.length));piIdx=(piIdx+4)%piDec.length;return c;
  }

  void _spawnPipe(){
    final minC=kGroundH+(kPipeGap+extraGap)/2+kMinPipeH,maxC=kH-(kPipeGap+extraGap)/2-kMinPipeH;
    final gC=minC+_rng.nextDouble()*(maxC-minC);
    pipes.add(Pipe(kW+kPipeW,gC,pipeSpeed,_piNext(),extraGap));
    if(_rng.nextDouble()<0.7)coins.add(Coin(kW+kPipeW+kPipeW/2,kH-gC));
  }

  void _burst(double x,double y,Color col,{int n=12}){
    for(var i=0;i<n;i++){
      final a=_rng.nextDouble()*pi*2,spd=100+_rng.nextDouble()*200;
      parts.add(Particle(x,y,cos(a)*spd,sin(a)*spd-100,0.6+_rng.nextDouble()*0.4,3+_rng.nextDouble()*4,col));
    }
  }

  void update(){
    if(!_loaded)return;
    final now=DateTime.now();
    if(_last==null){_last=now;return;}
    final dt=min((now.difference(_last!).inMicroseconds/1e6),0.05);
    _last=now; t+=dt;
    popups.removeWhere((p){p.timer-=dt;return p.timer<=0;});
    if(bonusPopup!=null){bonusPopup!.timer-=dt;if(bonusPopup!.timer<=0)bonusPopup=null;}
    parts.removeWhere((p){p.update(dt);return p.dead;});
    if(state==GS.game)_updateGame(dt);
  }

  void _updateGame(double dt){
    if(!started)return;
    if(mode==GameMode.timed){
      timedLeft-=dt;
      if(timedLeft<=0){timedLeft=0;timedDone=true;_endGame();return;}
    }
    p1.update(dt); p2?.update(dt);
    if(!p1.alive&&(p2==null||!p2!.alive)){if(p1.deathTimer>1.0){_endGame();return;}}
    else if(!p1.alive&&p2!=null){if(p1.deathTimer>0.5){_endGame();return;}}
    _updatePlayer(p1); if(p2!=null)_updatePlayer(p2!);
    pipeTimer+=dt; if(pipeTimer>=2.8){pipeTimer=0;_spawnPipe();}
    coins.removeWhere((c)=>c.collected);
    for(final c in coins){
      c.update(dt,pipeSpeed,mx:hasMagnet?p1.x:null,my:hasMagnet?p1.y:null);
      if(p1.alive&&p1.rect.overlaps(c.rect)){
        c.collected=true;final e=doubleCoins?2:1;sessionCoins+=e;
        floats.add(FloatText(c.x,c.y,'+$e'));_burst(c.x,c.y,const Color(0xFFFFD71E),n:8);
        _missionProgress('coins20',1);
      }
      if(p2!=null&&p2!.alive&&p2!.rect.overlaps(c.rect)){c.collected=true;score2++;floats.add(FloatText(c.x,c.y-20,'+1',color:const Color(0xFF64C8FF)));}
    }
    floats.removeWhere((f)=>f.timer<=0);
    for(final f in floats){f.y-=50*dt;f.timer-=dt;}
    for(var i=pipes.length-1;i>=0;i--){
      final p=pipes[i];p.update(dt);
      if(p.offScreen){pipes.removeAt(i);continue;}
      if(!p.scored&&p.centerX<p1.x){
        p.scored=true;score++;p1.addCombo();
        final cb=p1.combo>=3?p1.combo:0;
        if(cb>0){sessionCoins+=cb~/3;floats.add(FloatText(p1.x,p1.y-40,'COMBO x${p1.combo}! +${cb~/3}🪙',color:const Color(0xFFFF9600)));}
        if(p1.combo>save.maxCombo)save.maxCombo=p1.combo;
        save.totalPipes++;_missionProgress('pipes10',1);_missionProgress('score15',0,setVal:score);_checkAchs();
        if(score%5==0){final sm={'π/4':0.55,'π':1.0,'π²':1.5}[save.difficulty]!;pipeSpeed=min(pipeSpeed+10,350*sm*slowF);for(final pp in pipes)pp.speed=pipeSpeed;}
      }
      _pipeColl(p1,p,isP1:true);if(p2!=null)_pipeColl(p2!,p,isP1:false);
    }
  }

  void _updatePlayer(Player pl){
    if(!pl.alive)return;
    if(pl.y-kPlayerR<0){pl.y=kPlayerR;pl.vel=0;}
    if(pl.y+kPlayerR>kH-kGroundH){pl.y=kH-kGroundH-kPlayerR;_burst(pl.x,pl.y,pl.skin.glow);pl.alive=false;}
  }

  void _pipeColl(Player pl,Pipe p,{required bool isP1}){
    if(!pl.alive)return;
    if(pl.rect.overlaps(p.topRect)||pl.rect.overlaps(p.botRect)){
      if(pl.shielded&&!pl.shieldHit){
        pl.shielded=false;pl.shieldHit=true;pl.shieldAnim=0;
        _burst(pl.x,pl.y,const Color(0xFF64C8FF),n:16);
        if(isP1)_achUnlock('survivor');
      } else {_burst(pl.x,pl.y,pl.skin.glow);pl.alive=false;}
    }
  }

  void _endGame(){
    save.coins+=sessionCoins;save.totalCoinsEver+=sessionCoins;
    if(mode==GameMode.timed){if(score>save.highScoreTimed)save.highScoreTimed=score;}
    else{if(score>save.highScore)save.highScore=score;}
    save.addTopScore(score);save.gamesPlayed++;_missionProgress('play3',1);_checkAchs();save.save();state=GS.gameOver;
  }

  void _missionProgress(String id,int add,{int? setVal}){
    for(final m in save.missions){
      if(m.id==id&&!m.completed){
        if(setVal!=null)m.progress=max(m.progress,setVal);else m.progress+=add;
        if(m.progress>=m.target){m.completed=true;save.coins+=m.reward;popups.add(Popup('✅ Misja!','${m.name} +${m.reward}🪙',color:const Color(0xFF32C864)));save.save();}
      }
    }
  }

  void _checkAchs(){
    _achCond('first_flight',save.totalPipes>=1);_achCond('mathematician',save.highScore>=31);
    _achCond('centurion',save.highScore>=100);_achCond('millionaire',save.totalCoinsEver>=1000);
    _achCond('combo_king',save.maxCombo>=10);_achCond('speed_demon',save.difficulty=='π²'&&score>=20);
    _achCond('shopaholic',save.totalPurchases>=5);
  }
  void _achCond(String id,bool c){if(c)_achUnlock(id);}
  void _achUnlock(String id){
    if(!save.unlockedAchievements.contains(id)){
      save.unlockedAchievements.add(id);
      final a=achievements.firstWhere((x)=>x.id==id,orElse:()=>achievements[0]);
      popups.add(Popup('🏆 Osiągnięcie!','${a.icon} ${a.name}'));save.save();
    }
  }

  void onTap(Offset pt){
    switch(state){
      case GS.menu:
        if(bonusPopup!=null){save.claimBonus();bonusPopup=null;break;}
        if(ui['play']?.hit(pt)==true)      state=GS.modeSelect;
        else if(ui['shop']?.hit(pt)==true) {shopTab='player';shopScroll=0;state=GS.shop;}
        else if(ui['settings']?.hit(pt)==true) state=GS.settings;
        else if(ui['achievements']?.hit(pt)==true) state=GS.achievements;
        else if(ui['leaderboard']?.hit(pt)==true) state=GS.leaderboard;
        else if(ui['missions']?.hit(pt)==true) state=GS.missions;
        break;
      case GS.modeSelect:
        if(ui['mClassic']?.hit(pt)==true){mode=GameMode.classic;_initGame();state=GS.game;}
        else if(ui['mTimed']?.hit(pt)==true){mode=GameMode.timed;_initGame();state=GS.game;}
        else if(ui['mTwo']?.hit(pt)==true){mode=GameMode.twoPlayer;_initGame();state=GS.game;}
        else if(ui['back']?.hit(pt)==true) state=GS.menu;
        break;
      case GS.game:
        if(p2==null||pt.dy<kH*0.5){if(!started)started=true;p1.flap();}
        if(p2!=null&&pt.dy>=kH*0.5){if(!started)started=true;p2!.flap();}
        break;
      case GS.gameOver:
        if(ui['restart']?.hit(pt)==true){_initGame();state=GS.game;}
        else if(ui['shopGo']?.hit(pt)==true){shopTab='player';shopScroll=0;state=GS.shop;}
        else if(ui['menuGo']?.hit(pt)==true) state=GS.menu;
        break;
      case GS.shop:
        if(ui['back']?.hit(pt)==true){state=GS.menu;break;}
        if(ui['tabP']?.hit(pt)==true){shopTab='player';shopScroll=0;break;}
        if(ui['tabPi']?.hit(pt)==true){shopTab='pipe';shopScroll=0;break;}
        if(ui['tabU']?.hit(pt)==true){shopTab='upgrade';shopScroll=0;break;}
        for(final b in shopBtns){if(b.hit(pt)){b.action();break;}}
        break;
      case GS.settings:
        if(ui['easy']?.hit(pt)==true){save.difficulty='π/4';save.save();}
        else if(ui['normal']?.hit(pt)==true){save.difficulty='π';save.save();}
        else if(ui['hard']?.hit(pt)==true){save.difficulty='π²';save.save();}
        else if(ui['mute']?.hit(pt)==true){save.muted=!save.muted;save.save();}
        else if(ui['back']?.hit(pt)==true) state=GS.menu;
        break;
      default:
        if(ui['back']?.hit(pt)==true) state=GS.menu;
    }
  }
  void onScroll(double dy){if(state==GS.shop)shopScroll=max(0,shopScroll+dy*0.5);}
  PipeSkin get pipeSkin=>pipeSkins.firstWhere((s)=>s.id==save.pipeSkin,orElse:()=>pipeSkins[0]);
}

// ═══════════════════════════════════════════════════════════════════
//  SCREEN
// ═══════════════════════════════════════════════════════════════════
class GameScreen extends StatefulWidget{
  const GameScreen({super.key});
  @override State<GameScreen> createState()=>_GSS();
}
class _GSS extends State<GameScreen> with SingleTickerProviderStateMixin{
  late GameEngine eng; late AnimationController _c;
  @override void initState(){super.initState();eng=GameEngine();_c=AnimationController(vsync:this,duration:const Duration(days:1))..addListener(()=>setState(()=>eng.update()));_c.forward();}
  @override void dispose(){_c.dispose();super.dispose();}
  @override Widget build(BuildContext ctx){
    return Scaffold(backgroundColor:Colors.black,body:GestureDetector(
      onTapDown:(d){
        final s=MediaQuery.of(ctx).size;final sc=min(s.width/kW,s.height/kH);
        final ox=(s.width-kW*sc)/2,oy=(s.height-kH*sc)/2;
        eng.onTap(Offset((d.localPosition.dx-ox)/sc,(d.localPosition.dy-oy)/sc));
      },
      onVerticalDragUpdate:(d)=>eng.onScroll(d.delta.dy),
      child:CustomPaint(painter:GP(eng),child:const SizedBox.expand()),
    ));
  }
}

// ═══════════════════════════════════════════════════════════════════
//  PAINTER
// ═══════════════════════════════════════════════════════════════════
class GP extends CustomPainter{
  final GameEngine e; GP(this.e);
  late Canvas c; late double sc,ox,oy;
  final _p=Paint();

  @override void paint(Canvas canvas,Size size){
    c=canvas;sc=min(size.width/kW,size.height/kH);
    ox=(size.width-kW*sc)/2;oy=(size.height-kH*sc)/2;
    c.save();c.translate(ox,oy);c.scale(sc,sc);
    _bg();_stars();
    switch(e.state){
      case GS.menu:       _menu();break;
      case GS.modeSelect: _modeSelect();break;
      case GS.game:       _game();break;
      case GS.gameOver:   _gameOver();break;
      case GS.shop:       _shop();break;
      case GS.settings:   _settings();break;
      case GS.achievements:_achScreen();break;
      case GS.leaderboard: _lbScreen();break;
      case GS.missions:    _missionsScreen();break;
    }
    _popups();c.restore();
  }

  // ── utils ──────────────────────────────────────────────────────
  void _t(String txt,double x,double y,double fs,{Color col=Colors.white,bool bold=false,bool ctr=false,String? fam}){
    final tp=TextPainter(text:TextSpan(text:txt,style:TextStyle(fontSize:fs,color:col,fontWeight:bold?FontWeight.bold:FontWeight.normal,fontFamily:fam)),textDirection:TextDirection.ltr)..layout();
    tp.paint(c,Offset(ctr?x-tp.width/2:x,y-tp.height/2));
  }
  Rect _btn(String txt,double cx,double cy,Color col,{double w=220,double h=60}){
    final r=Rect.fromCenter(center:Offset(cx,cy),width:w,height:h);
    _p.color=col;c.drawRRect(RRect.fromRectAndRadius(r,const Radius.circular(10)),_p);
    _p.color=_lt(col,0.3);_p.style=PaintingStyle.stroke;_p.strokeWidth=2;
    c.drawRRect(RRect.fromRectAndRadius(r,const Radius.circular(10)),_p);_p.style=PaintingStyle.fill;
    _t(txt,cx,cy,19,bold:true,ctr:true);return r;
  }
  void _pnl(double x,double y,double w,double h,{double a=0.75}){
    _p.color=Color.fromRGBO(0,0,20,a);
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x,y,w,h),const Radius.circular(12)),_p);
  }
  Color _lt(Color col,double a)=>Color.fromARGB(col.alpha,min(255,col.red+(255*a).round()),min(255,col.green+(255*a).round()),min(255,col.blue+(255*a).round()));
  void _coin(int amt,double x,double y,{double sz=18}){
    _p.color=const Color(0xFFFFD71E);c.drawCircle(Offset(x+sz/2,y+sz/2),sz/2,_p);
    _p.color=const Color(0xFFC8A000);c.drawCircle(Offset(x+sz/2,y+sz/2),sz/2-2,_p);
    _t('π',x+sz/2,y+sz/2+1,sz*0.55,col:const Color(0xFFFFD71E),bold:true,ctr:true);
    _t('$amt',x+sz+5,y+sz/2,sz*0.9,col:const Color(0xFFFFD71E),bold:true);
  }

  // ── bg ─────────────────────────────────────────────────────────
  void _bg(){
    _p.shader=const LinearGradient(begin:Alignment.topCenter,end:Alignment.bottomCenter,colors:[Color(0xFF0C0C2E),Color(0xFF051420)]).createShader(Rect.fromLTWH(0,0,kW,kH));
    c.drawRect(Rect.fromLTWH(0,0,kW,kH),_p);_p.shader=null;
  }
  void _stars(){for(final s in e.stars){final tw=0.5+0.5*sin(e.t*2+s.x);_p.color=Colors.white.withOpacity(s.bright*tw*0.8);c.drawCircle(Offset(s.x,s.y),s.size,_p);}}
  void _ground(){_p.color=const Color(0xFF196432);c.drawRect(Rect.fromLTWH(0,kH-kGroundH,kW,kGroundH),_p);_p.color=const Color(0xFF23963C);c.drawRect(Rect.fromLTWH(0,kH-kGroundH,kW,8),_p);}

  // ── pipe ───────────────────────────────────────────────────────
  void _drawPipe(Pipe pipe){
    final sk=e.pipeSkin;const capH=28.0,capEx=12.0;final ix=pipe.x;
    if(pipe.topEnd>0){
      _p.color=sk.body;c.drawRect(Rect.fromLTWH(ix,0,kPipeW,max(0,pipe.topEnd-capH)),_p);
      _p.color=sk.lite;c.drawRect(Rect.fromLTWH(ix+14,0,10,max(0,pipe.topEnd-capH)),_p);
      _p.color=sk.dark;c.drawRect(Rect.fromLTWH(ix-capEx/2,pipe.topEnd-capH,kPipeW+capEx,capH),_p);
      _p.color=sk.lite;_p.style=PaintingStyle.stroke;_p.strokeWidth=2;c.drawRect(Rect.fromLTWH(ix-capEx/2,pipe.topEnd-capH,kPipeW+capEx,capH),_p);_p.style=PaintingStyle.fill;
    }
    if(pipe.botTop<kH){
      _p.color=sk.dark;c.drawRect(Rect.fromLTWH(ix-capEx/2,pipe.botTop,kPipeW+capEx,capH),_p);
      _p.color=sk.lite;_p.style=PaintingStyle.stroke;_p.strokeWidth=2;c.drawRect(Rect.fromLTWH(ix-capEx/2,pipe.botTop,kPipeW+capEx,capH),_p);_p.style=PaintingStyle.fill;
      final bby=pipe.botTop+capH;_p.color=sk.body;c.drawRect(Rect.fromLTWH(ix,bby,kPipeW,kH-bby),_p);
      _p.color=sk.lite;c.drawRect(Rect.fromLTWH(ix+14,bby,10,kH-bby),_p);
    }
    _t(pipe.label,pipe.centerX,(pipe.topEnd+pipe.botTop)/2,17,col:const Color(0xFFDCFF82),bold:true,ctr:true,fam:'monospace');
  }

  // ── player ─────────────────────────────────────────────────────
  void _drawPlayer(Player pl){
    final sk=pl.skin;const R=kPlayerR;
    final pls=0.6+0.4*sin(pl.pulse),gr=R*1.8*pls;
    _p.shader=RadialGradient(colors:[sk.glow.withOpacity(0.25),sk.glow.withOpacity(0)]).createShader(Rect.fromCircle(center:Offset(pl.x,pl.y),radius:gr));
    c.drawCircle(Offset(pl.x,pl.y),gr,_p);_p.shader=null;
    if(pl.shielded||pl.shieldHit){
      final sa=pl.shieldHit?0.9:0.5+0.3*sin(pl.pulse*2);
      _p.color=pl.shieldHit?Colors.red.withOpacity(sa):const Color(0xFF64C8FF).withOpacity(sa);
      _p.style=PaintingStyle.stroke;_p.strokeWidth=3;c.drawCircle(Offset(pl.x,pl.y),R+12,_p);_p.style=PaintingStyle.fill;
    }
    c.save();c.translate(pl.x,pl.y);c.rotate(pl.angle*pi/180);
    _p.color=sk.body.withOpacity(0.85);c.drawCircle(Offset.zero,R,_p);
    _p.color=sk.body;c.drawCircle(Offset.zero,R-4,_p);
    _t('π',0,2,R-2,col:pl.alive?sk.pi:sk.pi.withOpacity(0.5),bold:true,ctr:true,fam:'serif');
    c.restore();
    if(pl.combo>=3)_t('x${pl.combo}🔥',pl.x,pl.y-R-15,13,col:const Color(0xFFFF9600),bold:true,ctr:true);
  }

  // ── coin ───────────────────────────────────────────────────────
  void _drawCoin(Coin coin){
    if(coin.collected)return;final bob=3*sin(coin.anim),cy=coin.y+bob;
    _p.shader=RadialGradient(colors:[const Color(0xFFFFD71E).withOpacity(0.3),Colors.transparent]).createShader(Rect.fromCircle(center:Offset(coin.x,cy),radius:kCoinR*2));
    c.drawCircle(Offset(coin.x,cy),kCoinR*2,_p);_p.shader=null;
    _p.color=const Color(0xFFFFD71E);c.drawCircle(Offset(coin.x,cy),kCoinR,_p);
    _p.color=const Color(0xFFC8A000);c.drawCircle(Offset(coin.x,cy),kCoinR-2,_p);
    _p.color=const Color(0xFFFFE650);c.drawCircle(Offset(coin.x,cy),kCoinR-5,_p);
    _p.color=const Color(0xFFFFF064);_p.style=PaintingStyle.stroke;_p.strokeWidth=2;c.drawCircle(Offset(coin.x,cy),kCoinR,_p);_p.style=PaintingStyle.fill;
  }

  void _drawParts(){for(final p in e.parts){final a=(p.life/p.maxLife).clamp(0,1).toDouble();_p.color=p.color.withOpacity(a);c.drawCircle(Offset(p.x,p.y),p.size*a,_p);}}

  // ── popups ─────────────────────────────────────────────────────
  void _popups(){
    if(e.bonusPopup!=null){
      final bp=e.bonusPopup!;final a=min(1.0,bp.timer/0.5);
      c.save();c.globalAlpha=a;
      _pnl(kW/2-165,115,330,90,a:0.92);
      _p.color=bp.color;_p.style=PaintingStyle.stroke;_p.strokeWidth=2;
      c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(kW/2-165,115,330,90),const Radius.circular(12)),_p);_p.style=PaintingStyle.fill;
      _t(bp.title,kW/2,145,21,col:bp.color,bold:true,ctr:true);
      _t(bp.msg,kW/2,170,18,ctr:true);
      _t('Dotknij aby odebrać',kW/2,190,13,col:Colors.grey,ctr:true);
      c.restore();return;
    }
    var yo=0.0;
    for(final pop in e.popups){
      final a=min(1.0,pop.timer/0.5);c.save();c.globalAlpha=a;
      _pnl(kW/2-155,98+yo,310,68,a:0.92);
      _p.color=pop.color;_p.style=PaintingStyle.stroke;_p.strokeWidth=2;
      c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(kW/2-155,98+yo,310,68),const Radius.circular(12)),_p);_p.style=PaintingStyle.fill;
      _t(pop.title,kW/2,120+yo,16,col:pop.color,bold:true,ctr:true);
      _t(pop.msg,kW/2,148+yo,14,ctr:true);
      c.restore();yo+=76;
    }
  }

  // ── MENU ───────────────────────────────────────────────────────
  void _menu(){
    _ground();
    for(var i=0;i<6;i++){final a=e.t*0.4+i*1.05;final sx=kW*0.1+i*kW*0.16+sin(a)*18,sy=kH*0.35+cos(a*0.7+i)*60;c.save();c.globalAlpha=0.08+0.06*sin(e.t+i);_t('π',sx,sy,38,col:const Color(0xFFFFD71E),bold:true,ctr:true,fam:'serif');c.restore();}
    _pnl(kW/2-190,85,380,120);
    _t('FlappyPi',kW/2,135,46,col:const Color(0xFFFFD71E),bold:true,ctr:true);
    _t('Przelatuj przez cyfry liczby Pi!',kW/2,173,15,col:const Color(0xFFB4DCFF),ctr:true);
    _coin(e.save.coins,kW/2-32,196,sz:20);
    _t('Rekord: ${e.save.highScore}',kW/2,238,15,col:Colors.grey,ctr:true);
    if(e.save.canClaimBonus){_p.color=const Color(0xFF32C864);c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center:const Offset(kW/2,262),width:220,height:24),const Radius.circular(12)),_p);_t('🎁 Dzienny bonus dostępny!',kW/2,262,13,bold:true,ctr:true,col:Colors.black);}
    e.ui['play']        =BtnRect(_btn('▶  GRAJ',kW/2,310,const Color(0xFF199664)),(){e.state=GS.modeSelect;});
    e.ui['shop']        =BtnRect(_btn('🛒  SKLEP',kW/2,378,const Color(0xFF964614)),(){e.shopTab='player';e.shopScroll=0;e.state=GS.shop;});
    e.ui['missions']    =BtnRect(_btn('📋  MISJE',kW/2,446,const Color(0xFF196496)),(){e.state=GS.missions;});
    e.ui['achievements']=BtnRect(_btn('🏆  OSIĄGNIĘCIA',kW/2,514,const Color(0xFF645014)),(){e.state=GS.achievements;});
    e.ui['leaderboard'] =BtnRect(_btn('📊  WYNIKI',kW/2,582,const Color(0xFF321464)),(){e.state=GS.leaderboard;});
    e.ui['settings']    =BtnRect(_btn('⚙  USTAWIENIA',kW/2,650,const Color(0xFF3250A0)),(){e.state=GS.settings;});
  }

  // ── MODE SELECT ────────────────────────────────────────────────
  void _modeSelect(){
    _ground();_pnl(kW/2-215,75,430,610);
    _t('WYBIERZ TRYB',kW/2,115,34,col:const Color(0xFFFFD71E),bold:true,ctr:true);
    e.ui['mClassic']=BtnRect(_btn('',kW/2,225,const Color(0xFF199664),w:390,h:105),(){e.mode=GameMode.classic;e._initGame();e.state=GS.game;});
    _t('🎮 KLASYCZNY',kW/2,203,23,bold:true,ctr:true);_t('Leć jak najdalej. Bez limitu czasu.',kW/2,234,13,col:Colors.grey,ctr:true);
    e.ui['mTimed']=BtnRect(_btn('',kW/2,370,const Color(0xFF9B4600),w:390,h:105),(){e.mode=GameMode.timed;e._initGame();e.state=GS.game;});
    _t('⏱ NA CZAS (60s)',kW/2,348,23,bold:true,ctr:true);_t('Ile rur w 60 sekund? Rekord: ${e.save.highScoreTimed}',kW/2,379,13,col:Colors.grey,ctr:true);
    e.ui['mTwo']=BtnRect(_btn('',kW/2,515,const Color(0xFF5A1478),w:390,h:105),(){e.mode=GameMode.twoPlayer;e._initGame();e.state=GS.game;});
    _t('👥 DWA PTAKI',kW/2,493,23,bold:true,ctr:true);
    _t('Dwie osoby, jeden telefon!',kW/2,521,13,col:Colors.grey,ctr:true);
    _t('Góra = Gracz 1   Dół = Gracz 2',kW/2,538,12,col:const Color(0xFF96A0B4),ctr:true);
    e.ui['back']=BtnRect(_btn('← WRÓĆ',kW/2,655,const Color(0xFF3250A0),w:180,h:50),(){e.state=GS.menu;});
  }

  // ── GAME ───────────────────────────────────────────────────────
  void _game(){
    if(e.mode==GameMode.twoPlayer){_p.color=Colors.white.withOpacity(0.12);_p.style=PaintingStyle.stroke;_p.strokeWidth=1;c.drawLine(Offset(0,kH/2),Offset(kW,kH/2),_p);_p.style=PaintingStyle.fill;}
    for(final p in e.pipes)_drawPipe(p);
    for(final coin in e.coins)_drawCoin(coin);
    _ground();_drawParts();_drawPlayer(e.p1);if(e.p2!=null)_drawPlayer(e.p2!);
    for(final f in e.floats){c.save();c.globalAlpha=(f.timer/1.2).clamp(0,1);_t(f.txt,f.x,f.y,19,col:f.color,bold:true,ctr:true);c.restore();}
    if(e.mode==GameMode.twoPlayer){
      _t('P1: ${e.score}',kW/2-65,35,26,bold:true,ctr:true,col:e.p1.alive?Colors.white:Colors.red);
      _t('P2: ${e.score2}',kW/2+65,35,26,bold:true,ctr:true,col:e.p2!.alive?const Color(0xFF64C8FF):Colors.red);
    } else {_t('${e.score}',kW/2,40,34,bold:true,ctr:true);}
    _coin(e.save.coins+e.sessionCoins,8,8,sz:18);
    if(e.mode==GameMode.timed){final r=e.timedLeft.ceil();_t('⏱ ${r}s',kW-8,20,20,col:r<=10?const Color(0xFFFF4646):const Color(0xFF96D2FF),bold:true);}
    final sh=min(e.score*2,18);c.save();c.globalAlpha=0.7;_t('π = 3.${piDec.substring(0,sh)}...',kW/2,66,14,col:const Color(0xFF96D2FF),ctr:true,fam:'monospace');c.restore();
    if(e.p1.shielded)_t('🛡',kW-16,e.mode==GameMode.timed?46:18,20,ctr:true);
    if(!e.started){_pnl(kW/2-145,kH/2+48,290,52,a:0.82);_t(e.mode==GameMode.twoPlayer?'P1=góra  P2=dół  start':' Dotknij = start',kW/2,kH/2+74,17,bold:true,ctr:true);}
  }

  // ── GAME OVER ──────────────────────────────────────────────────
  void _gameOver(){
    _ground();c.save();c.globalAlpha=0.75;_p.color=Colors.black;c.drawRect(Rect.fromLTWH(0,0,kW,kH),_p);c.restore();
    _t('KONIEC GRY',kW/2,142,44,col:const Color(0xFFFF4646),bold:true,ctr:true);
    if(e.mode==GameMode.twoPlayer){
      _t(e.score>=e.score2?'🏆 Gracz 1 wygrywa!':'🏆 Gracz 2 wygrywa!',kW/2,190,24,col:const Color(0xFFFFD71E),bold:true,ctr:true);
      _t('P1: ${e.score}',kW/2,228,19,ctr:true);_t('P2: ${e.score2}',kW/2,254,19,col:const Color(0xFF64C8FF),ctr:true);
    } else {
      _t('Wynik: ${e.score}',kW/2,205,32,col:const Color(0xFFFFD71E),bold:true,ctr:true);
      final best=e.mode==GameMode.timed?e.save.highScoreTimed:e.save.highScore;
      _t('Rekord: $best',kW/2,252,19,col:Colors.grey,ctr:true);
      if(e.score==best&&e.score>0)_t('🎉 NOWY REKORD!',kW/2,278,17,col:const Color(0xFF32C864),bold:true,ctr:true);
    }
    _coin(e.save.coins,kW/2-32,298,sz:20);
    e.ui['restart']=BtnRect(_btn('▶  GRAJ PONOWNIE',kW/2,398,const Color(0xFF199664),w:270),(){e._initGame();e.state=GS.game;});
    e.ui['shopGo'] =BtnRect(_btn('🛒  SKLEP',kW/2,472,const Color(0xFF964614)),(){e.shopTab='player';e.shopScroll=0;e.state=GS.shop;});
    e.ui['menuGo'] =BtnRect(_btn('🏠  MENU',kW/2,546,const Color(0xFF3250A0)),(){e.state=GS.menu;});
  }

  // ── SHOP ───────────────────────────────────────────────────────
  void _shop(){
    _ground();e.shopBtns.clear();
    _t('🛒 SKLEP',kW/2,44,36,col:const Color(0xFFFFD71E),bold:true,ctr:true);
    _coin(e.save.coins,kW-85,21,sz:20);
    e.ui['tabP'] =BtnRect(_tab('Gracz',kW/2-140,80,e.shopTab=='player'),(){e.shopTab='player';e.shopScroll=0;});
    e.ui['tabPi']=BtnRect(_tab('Rury',kW/2,80,e.shopTab=='pipe'),(){e.shopTab='pipe';e.shopScroll=0;});
    e.ui['tabU'] =BtnRect(_tab('Ulepszenia',kW/2+140,80,e.shopTab=='upgrade'),(){e.shopTab='upgrade';e.shopScroll=0;});
    const aT=107.0,aB=kH-kGroundH-70;
    c.save();c.clipRect(Rect.fromLTWH(0,aT,kW,aB-aT));c.translate(0,-e.shopScroll);
    if(e.shopTab=='player')_shopSkins(playerSkins,'player',aT);
    else if(e.shopTab=='pipe')_shopSkins(pipeSkins,'pipe',aT);
    else _shopUpg(aT);
    c.restore();
    e.ui['back']=BtnRect(_btn('← WRÓĆ',kW/2,aB+35,const Color(0xFF3250A0),w:180,h:50),(){e.state=GS.menu;});
  }

  void _shopSkins(List skins,String type,double aT){
    const cols=2,iW=kW/cols-20,iH=150.0,pad=10.0;
    final owned=type=='player'?e.save.ownedPlayers:e.save.ownedPipes;
    final eqId=type=='player'?e.save.playerSkin:e.save.pipeSkin;
    for(var i=0;i<skins.length;i++){
      final sk=skins[i];final col=i%cols,row=i~/cols;
      final x=pad+col*(iW+pad),y=pad+row*(iH+pad);final sY=aT+y-e.shopScroll;
      final isO=owned.contains(sk.id),isE=sk.id==eqId;
      _p.color=isE?const Color(0xFF1E501E):isO?const Color(0xFF14143C):const Color(0xFF280A0A);
      c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x,y,iW,iH),const Radius.circular(10)),_p);
      _p.color=isE?const Color(0xFF32C864):isO?const Color(0xFF5050B4):const Color(0xFFB43232);
      _p.style=PaintingStyle.stroke;_p.strokeWidth=2;c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x,y,iW,iH),const Radius.circular(10)),_p);_p.style=PaintingStyle.fill;
      final px=x+iW/2;
      if(type=='player'){
        final ps=sk as PlayerSkin;
        _p.shader=RadialGradient(colors:[ps.glow.withOpacity(0.3),Colors.transparent]).createShader(Rect.fromCircle(center:Offset(px,y+50),radius:30));
        c.drawCircle(Offset(px,y+50),30,_p);_p.shader=null;_p.color=ps.body;c.drawCircle(Offset(px,y+50),28,_p);
        _t('π',px,y+52,23,col:ps.pi,bold:true,ctr:true,fam:'serif');
      } else {
        final ps=sk as PipeSkin;_p.color=ps.body;c.drawRect(Rect.fromLTWH(px-15,y+20,30,60),_p);
        _p.color=ps.dark;c.drawRect(Rect.fromLTWH(px-20,y+20,40,12),_p);
        _p.color=ps.lite;_p.style=PaintingStyle.stroke;_p.strokeWidth=2;c.drawRect(Rect.fromLTWH(px-20,y+20,40,12),_p);_p.style=PaintingStyle.fill;
      }
      _t(sk.name,px,y+94,15,bold:true,ctr:true);
      if(isE){_t('✓ ZAŁOŻONO',px,y+120,12,col:const Color(0xFF64FF64),ctr:true);}
      else if(isO){
        final bx=px-50,by=y+110;_p.color=const Color(0xFF1E7850);c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(bx,by,100,30),const Radius.circular(6)),_p);_t('ZAŁÓŻ',px,by+15,13,ctr:true);
        e.shopBtns.add(BtnRect(Rect.fromLTWH(bx,sY+110,100,30),(){if(type=='player')e.save.playerSkin=sk.id;else e.save.pipeSkin=sk.id;e.save.save();}));
      } else {
        final bx=px-60,by=y+108;final canB=e.save.coins>=sk.price;
        _p.color=canB?const Color(0xFF825008):const Color(0xFF3C2828);c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(bx,by,120,32),const Radius.circular(6)),_p);
        _t('🪙 ${sk.price}',px,by+16,13,col:canB?const Color(0xFFFFD71E):Colors.grey,ctr:true);
        if(canB)e.shopBtns.add(BtnRect(Rect.fromLTWH(bx,sY+108,120,32),(){
          if(e.save.coins<sk.price)return;e.save.coins=(e.save.coins-sk.price).toInt();
          if(type=='player'){e.save.ownedPlayers.add(sk.id);e.save.playerSkin=sk.id;}
          else{e.save.ownedPipes.add(sk.id);e.save.pipeSkin=sk.id;}
          e.save.totalPurchases++;e.save.save();e._achCond('shopaholic',e.save.totalPurchases>=5);
        }));
      }
    }
  }

  void _shopUpg(double aT){
    const iH=110.0,pad=10.0;
    for(var i=0;i<upgrades.length;i++){
      final upg=upgrades[i];final lvl=e.save.upgradeLevel(upg.id),maxed=lvl>=upg.max;
      final y=pad+i*(iH+pad);final sY=aT+y-e.shopScroll;
      _p.color=maxed?const Color(0xFF143C14):const Color(0xFF14143C);c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(pad,y,kW-pad*2,iH),const Radius.circular(10)),_p);
      _p.color=maxed?const Color(0xFF32C864):const Color(0xFF5050B4);_p.style=PaintingStyle.stroke;_p.strokeWidth=2;c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(pad,y,kW-pad*2,iH),const Radius.circular(10)),_p);_p.style=PaintingStyle.fill;
      _t(upg.name,pad+16,y+24,17,bold:true);_t(upg.desc,pad+16,y+46,13,col:Colors.grey);_t('Poziom: $lvl/${upg.max}',pad+16,y+67,13,col:const Color(0xFFB4DCFF));
      if(maxed){_t('★ MAX',kW-pad-16,y+iH/2,14,col:const Color(0xFFFFD71E));}
      else{
        final price=upg.price*(lvl+1);final canB=e.save.coins>=price;
        const bx=kW-150.0;final by=y+iH/2-20;
        _p.color=canB?const Color(0xFF825008):const Color(0xFF3C2828);c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(bx,by,130,40),const Radius.circular(6)),_p);
        _t('🪙 $price',bx+65,by+20,14,col:canB?const Color(0xFFFFD71E):Colors.grey,bold:true,ctr:true);
        if(canB)e.shopBtns.add(BtnRect(Rect.fromLTWH(bx,sY+iH/2-20,130,40),(){
          if(e.save.coins<price)return;e.save.coins-=price;e.save.upgradesMap[upg.id]=(e.save.upgradesMap[upg.id]??0)+1;
          e.save.totalPurchases++;e.save.save();e._achCond('shopaholic',e.save.totalPurchases>=5);
        }));
      }
    }
  }

  Rect _tab(String txt,double cx,double cy,bool active){
    const w=130.0,h=38.0;final r=Rect.fromCenter(center:Offset(cx,cy),width:w,height:h);
    _p.color=active?const Color(0xFF3C64B4):const Color(0xFF19233C);c.drawRRect(RRect.fromRectAndRadius(r,const Radius.circular(8)),_p);
    if(active){_p.color=const Color(0xFF78B4FF);_p.style=PaintingStyle.stroke;_p.strokeWidth=2;c.drawRRect(RRect.fromRectAndRadius(r,const Radius.circular(8)),_p);_p.style=PaintingStyle.fill;}
    _t(txt,cx,cy,14,bold:true,ctr:true);return r;
  }

  // ── SETTINGS ───────────────────────────────────────────────────
  void _settings(){
    _ground();_pnl(kW/2-205,148,410,380);
    _t('USTAWIENIA',kW/2,185,36,col:const Color(0xFFFFD71E),bold:true,ctr:true);
    _t('Poziom trudności:',kW/2,245,18,col:const Color(0xFFB4DCFF),ctr:true);
    final d=e.save.difficulty;
    e.ui['easy']  =BtnRect(_diffBtn('π/4','ŁATWY',kW/2-130,312,d=='π/4'?const Color(0xFF146450):const Color(0xFF1E3C28)),(){e.save.difficulty='π/4';e.save.save();});
    e.ui['normal']=BtnRect(_diffBtn('π','NORMALNY',kW/2,312,d=='π'?const Color(0xFF646414):const Color(0xFF3C3C14)),(){e.save.difficulty='π';e.save.save();});
    e.ui['hard']  =BtnRect(_diffBtn('π²','TRUDNY',kW/2+130,312,d=='π²'?const Color(0xFF641414):const Color(0xFF461414)),(){e.save.difficulty='π²';e.save.save();});
    _t({'π/4':'Wolniejsze rury','π':'Klasyczna prędkość','π²':'Rury bez litości!'}[d]!,kW/2,365,14,col:Colors.grey,ctr:true);
    e.ui['mute']=BtnRect(_btn(e.save.muted?'🔇 WYCISZONO':'🔊 DŹWIĘK: ON',kW/2,412,e.save.muted?const Color(0xFF501414):const Color(0xFF145014),w:220,h:46),(){e.save.muted=!e.save.muted;e.save.save();});
    e.ui['back']=BtnRect(_btn('← WRÓĆ',kW/2,470,const Color(0xFF3250A0),w:180,h:50),(){e.state=GS.menu;});
  }

  Rect _diffBtn(String sym,String lbl,double cx,double cy,Color col){
    const w=110.0,h=72.0;final r=Rect.fromCenter(center:Offset(cx,cy),width:w,height:h);
    _p.color=col;c.drawRRect(RRect.fromRectAndRadius(r,const Radius.circular(10)),_p);
    _p.color=_lt(col,0.3);_p.style=PaintingStyle.stroke;_p.strokeWidth=2;c.drawRRect(RRect.fromRectAndRadius(r,const Radius.circular(10)),_p);_p.style=PaintingStyle.fill;
    _t(sym,cx,cy-8,27,bold:true,ctr:true,fam:'serif');_t(lbl,cx,cy+22,11,col:Colors.grey,ctr:true);return r;
  }

  // ── ACHIEVEMENTS ───────────────────────────────────────────────
  void _achScreen(){
    _ground();_t('🏆 OSIĄGNIĘCIA',kW/2,44,32,col:const Color(0xFFFFD71E),bold:true,ctr:true);
    _t('${e.save.unlockedAchievements.length}/${achievements.length} odblokowanych',kW/2,76,14,col:Colors.grey,ctr:true);
    const pad=10.0,iH=75.0;
    for(var i=0;i<achievements.length;i++){
      final a=achievements[i];final isU=e.save.unlockedAchievements.contains(a.id);final y=96.0+i*(iH+pad);
      _p.color=isU?const Color(0xFF1E3C14):const Color(0xFF1A1A2E);c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(pad,y,kW-pad*2,iH),const Radius.circular(10)),_p);
      _p.color=isU?const Color(0xFFFFD71E):const Color(0xFF404060);_p.style=PaintingStyle.stroke;_p.strokeWidth=2;c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(pad,y,kW-pad*2,iH),const Radius.circular(10)),_p);_p.style=PaintingStyle.fill;
      _t(a.icon,pad+30,y+iH/2,26,ctr:true);
      _t(a.name,pad+60,y+24,15,bold:true,col:isU?Colors.white:Colors.grey);
      _t(a.desc,pad+60,y+49,12,col:isU?Colors.grey:const Color(0xFF404060));
      if(isU)_t('✓',kW-pad-20,y+iH/2,20,col:const Color(0xFF64FF64),ctr:true);
    }
    e.ui['back']=BtnRect(_btn('← WRÓĆ',kW/2,kH-kGroundH-34,const Color(0xFF3250A0),w:180,h:48),(){e.state=GS.menu;});
  }

  // ── LEADERBOARD ────────────────────────────────────────────────
  void _lbScreen(){
    _ground();_pnl(kW/2-205,68,410,590);
    _t('📊 TOP WYNIKI',kW/2,104,32,col:const Color(0xFFFFD71E),bold:true,ctr:true);
    _pnl(kW/2-90,128,180,60,a:0.5);_t('Klasyczny',kW/2-90+90,148,15,bold:true,ctr:true);_t('${e.save.highScore}',kW/2-90+90,170,22,col:const Color(0xFFFFD71E),bold:true,ctr:true);
    _pnl(kW/2+10,128,180,60,a:0.5);_t('Na czas',kW/2+10+90,148,15,bold:true,ctr:true);_t('${e.save.highScoreTimed}',kW/2+10+90,170,22,col:const Color(0xFF64C8FF),bold:true,ctr:true);
    _p.color=Colors.white.withOpacity(0.12);_p.style=PaintingStyle.stroke;_p.strokeWidth=1;c.drawLine(Offset(kW/2,198),Offset(kW/2,590),_p);_p.style=PaintingStyle.fill;
    _t('Ostatnie wyniki:',kW/2,210,14,col:Colors.grey,ctr:true);
    final medals=['🥇','🥈','🥉','4.','5.'];
    for(var i=0;i<min(e.save.topScores.length,5);i++){
      final y=234.0+i*54;_p.color=i==0?const Color(0xFF3C2800):const Color(0xFF14143C);c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(kW/2-165,y-22,330,46),const Radius.circular(8)),_p);
      _t(medals[i],kW/2-105,y,20,ctr:true);_t('${e.save.topScores[i]}',kW/2+20,y,22,col:i==0?const Color(0xFFFFD71E):Colors.white,bold:true,ctr:true);_t('pkt',kW/2+62,y,13,col:Colors.grey,ctr:true);
    }
    if(e.save.topScores.isEmpty)_t('Brak wyników — zagraj!',kW/2,316,15,col:Colors.grey,ctr:true);
    _t('Gry: ${e.save.gamesPlayed}   Rury: ${e.save.totalPipes}   Combo: x${e.save.maxCombo}',kW/2,538,13,col:Colors.grey,ctr:true);
    e.ui['back']=BtnRect(_btn('← WRÓĆ',kW/2,kH-kGroundH-34,const Color(0xFF3250A0),w:180,h:48),(){e.state=GS.menu;});
  }

  // ── MISSIONS ───────────────────────────────────────────────────
  void _missionsScreen(){
    _ground();_t('📋 MISJE DZIENNE',kW/2,44,30,col:const Color(0xFFFFD71E),bold:true,ctr:true);_t('Resetują się każdego dnia',kW/2,74,13,col:Colors.grey,ctr:true);
    const pad=10.0,iH=112.0;
    for(var i=0;i<e.save.missions.length;i++){
      final m=e.save.missions[i];final y=92.0+i*(iH+pad);
      _p.color=m.completed?const Color(0xFF143C14):const Color(0xFF14143C);c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(pad,y,kW-pad*2,iH),const Radius.circular(10)),_p);
      _p.color=m.completed?const Color(0xFF32C864):const Color(0xFF5050B4);_p.style=PaintingStyle.stroke;_p.strokeWidth=2;c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(pad,y,kW-pad*2,iH),const Radius.circular(10)),_p);_p.style=PaintingStyle.fill;
      _t(m.name,pad+16,y+22,17,bold:true,col:m.completed?const Color(0xFF64FF64):Colors.white);
      _t(m.desc,pad+16,y+44,13,col:Colors.grey);
      final bW=kW-pad*2-32;_p.color=const Color(0xFF1E1E3C);c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(pad+16,y+62,bW,14),const Radius.circular(7)),_p);
      _p.color=m.completed?const Color(0xFF32C864):const Color(0xFF3264C8);c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(pad+16,y+62,bW*m.pct,14),const Radius.circular(7)),_p);
      _t('${m.progress}/${m.target}',pad+16+bW/2,y+69,11,col:Colors.white,ctr:true);
      _t('🪙 +${m.reward}',kW-pad-50,y+30,15,col:m.completed?Colors.grey:const Color(0xFFFFD71E),bold:true,ctr:true);
      if(m.completed)_t('✓',kW-pad-20,y+75,22,col:const Color(0xFF64FF64),ctr:true);
    }
    e.ui['back']=BtnRect(_btn('← WRÓĆ',kW/2,kH-kGroundH-34,const Color(0xFF3250A0),w:180,h:48),(){e.state=GS.menu;});
  }

  @override bool shouldRepaint(covariant CustomPainter o)=>true;
}

extension _CA on Canvas{set globalAlpha(double v){}}
