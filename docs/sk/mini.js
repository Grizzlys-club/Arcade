/* MiniScene / Seat / BearNode: 1:1 aus Core.swift */
(()=>{
'use strict';
const {Node,Sprite,Label,Shape,Crop,A,Gfx,Theme,rgba,white,label,clamp,Rand,easeOut,easeInOut}=SK;
const SW=390;let SH=844;const bandH=40,topInset=36,bottomInset=22,bearAspect=918/777;
const SKC={SW,get SH(){return SH},set SH(v){SH=v},bandH,topInset,bottomInset,bearAspect};
const BEARB=Gfx.image('img/bear_body.png'),BEARD=Gfx.image('img/bear_detail.png');
const skinOf=id=>(window.META.SKINS.find(k=>k.id===id)||window.META.SKINS[0]);
const isDark=sk=>(parseInt(sk.color.slice(1,3),16)*.3+parseInt(sk.color.slice(3,5),16)*.6+parseInt(sk.color.slice(5,7),16)*.1)/255<.45;

/* ---------- Bär ---------- */
class BearNode extends Node{
 constructor(skin,height,faceRight){super();this.height=height;const w=height*bearAspect,dark=isDark(skin);
  this.shadow=new Sprite(Gfx.shadow(),w*.85,height*.22);this.shadow.y=2;this.shadow.z=-2;this.add(this.shadow);
  this.visual=new Node();this.add(this.visual);
  const outline=new Sprite(BEARB,w*1.07,height*1.07);outline.ax=.5;outline.ay=.03;outline.color=dark?'#fff':'rgb(26,26,26)';outline.cbf=1;outline.z=0;this.visual.add(outline);
  const body=new Sprite(BEARB,w,height);body.ay=0;body.color=skin.color;body.cbf=1;body.z=1;this.visual.add(body);
  const detail=new Sprite(BEARD,w,height);detail.ay=0;detail.z=2;this.visual.add(detail);
  const num=label(String(skin.num),height*.2,dark?Theme.orange:rgba(.1,.1,.1,.85));num.x=w*.2;num.y=height*.55;num.z=3;this.visual.add(num);this.numberLabel=num;
  this.addAccessory(skin.acc,w,height);this.setFacing(faceRight)}
 addAccessory(acc,w,h){const hx=-.12*w;
  if(acc==='crown'){const cw=w*.2,ch=h*.13,s=new Shape();s.path=c=>{c.beginPath();c.moveTo(-cw/2,0);c.lineTo(-cw/2,ch);c.lineTo(-cw/4,ch*.6);c.lineTo(0,ch*1.1);c.lineTo(cw/4,ch*.6);c.lineTo(cw/2,ch);c.lineTo(cw/2,0);c.closePath()};s.fill=rgba(1,.84,.1);s.stroke=rgba(.6,.4,0);s.lw=2;s.x=hx;s.y=h*.93;s.rot=.15;s.z=4;this.visual.add(s)}
  if(acc==='headband'){const s=Shape.rect(w*.26,h*.05,3);s.fill='#fff';s.stroke=Theme.orange;s.lw=2;s.x=hx;s.y=h*.86;s.rot=-.12;s.z=4;this.visual.add(s)}
  if(acc==='helmet'){const s=Shape.ellipse(w*.27,h*.16);s.fill=white(.95);s.stroke=white(.2);s.lw=2;s.x=hx;s.y=h*.93;s.rot=-.05;s.z=4;this.visual.add(s)}}
 setFacing(right){this.visual.sx=right?-1:1;this.numberLabel.sx=right?-1:1}
 get facingRight(){return this.visual.sx<0}
 startBob(amount,dur){amount=amount==null?3:amount;dur=dur==null?.35:dur;this.visual.removeAction('bob');const up=SK.easeInOut(A.moveBy(0,amount,dur));this.visual.run(A.forever(A.sequence([up,up.reversed()])),'bob')}
 stopBob(){this.visual.removeAction('bob');this.visual.x=0;this.visual.y=0}
 startRun(speed){speed=speed==null?.14:speed;this.visual.removeAction('run');const a=A.rotateTo(.07,speed),b=A.rotateTo(-.07,speed),hop=A.sequence([A.moveBy(0,5,speed),A.moveBy(0,-5,speed)]);this.visual.run(A.forever(A.group([A.sequence([a,b]),A.sequence([hop,hop])])),'run')}
 stopRun(){this.visual.removeAction('run');this.visual.rot=0;this.visual.x=0;this.visual.y=0}
 squash(){this.visual.run(A.sequence([A.scaleYTo(.85,.06),A.scaleYTo(1,.1)]),'squash')}
 celebrate(){const up=easeOut(A.moveBy(0,18,.16));this.run(A.repeat(A.sequence([up,up.reversed()]),4),'cel')}
}

/* ---------- Platz (Seat) ---------- */
class Seat{
 constructor(index,setup,skill,edge,zone){this.index=index;this.name=setup.name;this.skin=skinOf(setup.skin);this.isCPU=!!setup.cpu;this.color=Theme.seat[index%4];this.skill=skill;this.edge=edge;this.zone=zone;this.score=0;this.alive=true;this.scoreLabel=null;this.scene=null;
  if(edge==='bottom'){this.rotation=0;this.w=zone.w;this.h=zone.h}else if(edge==='top'){this.rotation=Math.PI;this.w=zone.w;this.h=zone.h}else if(edge==='left'){this.rotation=-Math.PI/2;this.w=zone.h;this.h=zone.w}else{this.rotation=Math.PI/2;this.w=zone.h;this.h=zone.w}
  this.size={width:this.w,height:this.h};
  this.node=new Node();this.node.x=zone.x+zone.w/2;this.node.y=zone.y+zone.h/2;this.node.rot=this.rotation;
  this.field=new Crop(this.w,this.h);this.node.add(this.field);
  {const W=Math.ceil(this.w),H=Math.ceil(this.h),ice=new Sprite(Gfx.texture('ice'+W+'x'+H,W,H,1.5,c=>{
    const g=c.createLinearGradient(0,0,0,H);g.addColorStop(0,'#0e2336');g.addColorStop(.5,'#16344d');g.addColorStop(1,'#0b1d2e');c.fillStyle=g;c.fillRect(0,0,W,H);
    const r=c.createRadialGradient(W/2,H*.42,0,W/2,H*.42,Math.max(W,H)*.7);r.addColorStop(0,'rgba(190,230,255,.28)');r.addColorStop(1,'rgba(190,230,255,0)');c.fillStyle=r;c.fillRect(0,0,W,H);
    c.lineCap='round';let s=W*131+H*7;const rn=()=>(s=(s*16807)%2147483647)/2147483647;
    for(let i=0;i<46;i++){const x=rn()*W,y=rn()*H,l=20+rn()*90,a=(rn()-.5)*1.2;c.strokeStyle='rgba(220,240,255,'+(.04+rn()*.07)+')';c.lineWidth=.6+rn()*.8;c.beginPath();c.moveTo(x,y);c.quadraticCurveTo(x+Math.cos(a)*l*.5,y+Math.sin(a)*l*.5+rn()*8,x+Math.cos(a)*l,y+Math.sin(a)*l);c.stroke()}
    c.strokeStyle='rgba(255,90,60,.16)';c.lineWidth=3;c.beginPath();c.moveTo(0,H*.5);c.lineTo(W,H*.5);c.stroke();
    c.strokeStyle='rgba(80,150,255,.14)';c.lineWidth=2.5;[.2,.8].forEach(k=>{c.beginPath();c.moveTo(0,H*k);c.lineTo(W,H*k);c.stroke()});
    c.strokeStyle='rgba(255,90,60,.12)';c.lineWidth=2;c.beginPath();c.arc(W/2,H*.5,Math.min(W,H)*.16,0,7);c.stroke()}),W,H);ice.z=-900;this.field.add(ice)}}
 get center(){return{x:this.zone.x+this.zone.w/2,y:this.zone.y+this.zone.h/2}}
 local(p){const dx=p.x-(this.zone.x+this.zone.w/2),dy=p.y-(this.zone.y+this.zone.h/2),c=Math.cos(-this.rotation),s=Math.sin(-this.rotation);return{x:dx*c-dy*s,y:dx*s+dy*c}}
 toScene(l){const c=Math.cos(this.rotation),s=Math.sin(this.rotation);return{x:this.zone.x+this.zone.w/2+l.x*c-l.y*s,y:this.zone.y+this.zone.h/2+l.x*s+l.y*c}}
 dirToScene(v){const c=Math.cos(this.rotation),s=Math.sin(this.rotation);return{dx:v.dx*c-v.dy*s,dy:v.dx*s+v.dy*c}}
 contains(p){return Math.abs(p.x)<=this.w/2&&Math.abs(p.y)<=this.h/2}
 floatText(text,at,color,size){size=(size||22)*1.12;const l=label(text,size,color||'#fff');l.x=at.x;l.y=at.y;l.z=300;l.setScale(.2);this.node.add(l);
  const g=new Sprite(Gfx.glow(),size*3.2,size*2,null);g.color=color||'#fff';g.cbf=1;g.blend='add';g.alpha=.55;g.z=-1;l.add(g);
  l.run(A.sequence([A.scaleTo(1.45,.09),A.scaleTo(1,.1),A.group([A.moveBy(0,46,.7),A.sequence([A.wait(.4),A.fadeOut(.35)])]),A.remove()]))}
 burst(at,color,count,speed){count=count==null?10:count;speed=speed==null?120:speed;count=Math.min(40,Math.ceil(count*1.7));
  const ring=new Sprite(Gfx.circle(20,'rgba(0,0,0,0)',color),40,40);ring.x=at.x;ring.y=at.y;ring.z=249;ring.blend='add';this.field.add(ring);ring.setScale(.2);ring.run(A.sequence([A.group([A.scaleTo(1+speed/90,.35),A.fadeOut(.35)]),A.remove()]));
  const gl=new Sprite(Gfx.glow(),speed*.9,speed*.9);gl.color=color;gl.cbf=1;gl.blend='add';gl.x=at.x;gl.y=at.y;gl.z=248;gl.alpha=.8;this.field.add(gl);gl.run(A.sequence([A.group([A.fadeOut(.3),A.scaleTo(1.6,.3)]),A.remove()]));
  for(let i=0;i<count;i++){const spark=i%3===0,s=new Sprite(Gfx.dot(),spark?3:7,spark?14:7);s.color=i%5===0?'#fff':color;s.cbf=1;s.blend='add';s.x=at.x;s.y=at.y;s.z=250;this.field.add(s);const a=Math.random()*Math.PI*2,d=(.4+Math.random()*.8)*speed;
   if(spark)s.rot=a-Math.PI/2;const t=.45+Math.random()*.35;s.run(A.sequence([A.group([A.moveBy(Math.cos(a)*d,Math.sin(a)*d-(spark?0:20),t),A.fadeOut(t),A.scaleTo(.2,t)]),A.remove()]))}}
 banner(text,color,size,duration){size=size==null?44:size;duration=duration==null?.8:duration;const l=label(text,Math.min(size,this.w*.16+14),color||this.color);l.z=700;l.setScale(.3);this.node.add(l);
  l.run(A.sequence([A.scaleTo(1,.15),A.wait(duration),A.group([A.fadeOut(.2),A.scaleTo(1.3,.2)]),A.remove()]))}
 flash(color,alpha,duration){const f=new Sprite(null,this.w,this.h,color);f.alpha=alpha==null?.45:alpha;f.z=600;this.node.add(f);f.run(A.sequence([A.fadeOut(duration==null?.35:duration),A.remove()]))}
 shake(amt){amt=amt==null?5:amt;if(amt>=6&&this.scene){this.scene.hitStop(Math.min(.08,.02+amt*.006));Juice.haptic('medium')}this.field.removeAction('shake');this.field.x=0;this.field.y=0;const acts=[];amt*=1.4;for(let i=0;i<9;i++)acts.push(A.moveTo((Math.random()*2-1)*amt*(1-i/10),(Math.random()*2-1)*amt*(1-i/10),.03));acts.push(A.moveTo(0,0,.03));this.field.run(A.sequence(acts),'shake')}
 knockOut(text){if(!this.alive)return;this.alive=false;const dim=new Sprite(null,this.w,this.h,white(0,.55));dim.z=500;this.node.add(dim);const l=label(text||'RAUS',Math.min(40,this.w*.18),white(1,.9));l.z=501;this.node.add(l)}
}

/* ---------- Basis-Szene ---------- */
class MiniScene extends Node{
 static get layout(){return 'zones'}
 static get stripThickness(){return 96}
 constructor(){super();this.seats=[];this.difficulty=1;this.duration=0;this.elapsed=0;this.stats={};this.sharedSeed=Math.floor(Math.random()*2147483646)+1;this.onFinish=null;this.onPause=null;this.phase='countdown';this.userPaused=false;this.activeSeatIndex=0;this.turnLabels=[];this.useCountdown=true;this.finished=false;this.arena={x:0,y:0,w:SW,h:SH};this.bandY=SH/2;this.world=new Node();this.hud=new Node();this.timeBar=null;this.timeBarWidth=0;this.touchOwner={};this.countdownTime=3.2;this.lastCount=99;this.built=false;this.activeBursts=0;this.hitStopT=0;this.timeScale=1;this.slowT=0;this.leader=-1;this.leadAt=-9;this.pulseSec=-1}
 get layout(){return this.constructor.layout}
 get n(){return this.seats.length}
 configure(players,difficulty){this.difficulty=difficulty;const lay=this.layout,count=Math.max(1,Math.min(4,players.length)),placed=[],usableBottom=bottomInset,usableTop=SH-topInset;
  if(lay==='zones'){const hh=(usableTop-usableBottom-bandH)/2,midBottom=usableBottom,topY=usableBottom+hh+bandH;this.bandY=usableBottom+hh+bandH/2;
   if(count<=2){placed.push(['bottom',{x:0,y:midBottom,w:SW,h:hh}]);placed.push(['top',{x:0,y:topY,w:SW,h:hh}])}
   else{const w=SW/2-2;placed.push(['bottom',{x:0,y:midBottom,w,h:hh}]);placed.push(['bottom',{x:SW/2+2,y:midBottom,w,h:hh}]);placed.push(['top',{x:SW/2+2,y:topY,w,h:hh}]);placed.push(['top',{x:0,y:topY,w,h:hh}])}
   this.arena={x:0,y:0,w:SW,h:SH}}
  else if(lay==='turns'){const full={x:0,y:usableBottom+30,w:SW,h:usableTop-usableBottom-30};for(let i=0;i<count;i++)placed.push(['bottom',full]);this.arena=full;this.bandY=usableBottom+15}
  else{const t=this.constructor.stripThickness,ts=t*.8,sides=count>=3,x0=sides?ts:0,x1=sides?SW-ts:SW;
   placed.push(['bottom',{x:x0,y:usableBottom,w:x1-x0,h:t}]);placed.push(['top',{x:x0,y:usableTop-t,w:x1-x0,h:t}]);placed.push(['left',{x:0,y:usableBottom+t,w:ts,h:usableTop-usableBottom-2*t}]);placed.push(['right',{x:SW-ts,y:usableBottom+t,w:ts,h:usableTop-usableBottom-2*t}]);
   this.arena={x:x0,y:usableBottom+t,w:x1-x0,h:usableTop-usableBottom-2*t}}
  const levels=[.04,.14,.26,.42,.64],base=levels[Math.max(0,Math.min(4,difficulty))],jitter=difficulty>=4?0:.06;this.seats=[];
  for(let i=0;i<count;i++){const skill=Math.max(.1,Math.min(1,base+(Math.random()*2-1)*jitter)),s=new Seat(i,players[i],skill,placed[i][0],placed[i][1]);s.scene=this;this.seats.push(s)}}
 setupGame(){}gameStarted(){}gameUpdate(dt){}timeUp(){this.finishGame()}began(){}moved(){}ended(){}
 build(){if(this.built)return;this.built=true;this.add(this.world);this.add(this.hud);this.hud.z=1000;this.buildBackground();
  this.seats.forEach(s=>{s.node.z=10;this.world.add(s.node);this.buildSeatChrome(s)});this.setupGame();this.buildHUD();if(!this.useCountdown){this.phase='playing';this.gameStarted()}}
 buildBackground(){const bg=new Sprite(Gfx.backdrop('game'+SH,rgba(.07,.06,.14),rgba(.02,.02,.05),Theme.orange,SW,SH),SW,SH);bg.ax=0;bg.ay=0;bg.z=-100;this.world.add(bg);this.bgSprite=bg;
  if(this.layout==='zones'&&this.seats.length===3){const hh=(SH-topInset-bottomInset-bandH)/2,logo=new Sprite(Gfx.logo,0,0),d=Math.min(SW/2,hh)*.7;logo.w=d;logo.h=d;logo.x=SW/4;logo.y=this.bandY+bandH/2+hh/2;logo.alpha=.55;logo.rot=Math.PI;logo.z=-50;this.world.add(logo);logo.run(A.forever(A.sequence([A.scaleTo(1.05,1.2),A.scaleTo(.95,1.2)])))}}
 buildSeatChrome(s){const panel=new Sprite(Gfx.pill(s.w,s.h,s.color.replace(/[\d.]+\)$/,'.07)'),s.color.replace(/[\d.]+\)$/,'.55)'),18,false),s.w,s.h);panel.z=-40;s.node.add(panel);
  const fs=s.h<120?12:14,name=label(s.name.toUpperCase()+(s.isCPU?' · CPU':''),fs,s.color);name.ha='left';name.x=-s.w/2+14;name.y=s.h/2-14;name.z=400;name.alpha=.9;s.node.add(name);
  const sc=label('0',fs+8,'#fff');sc.ha='right';sc.x=s.w/2-14;sc.y=s.h/2-16;sc.z=400;s.node.add(sc);s.scoreLabel=sc}
 buildHUD(){const lay=this.layout;let pp;if(lay==='zones')pp={x:24,y:this.bandY};else if(lay==='turns')pp={x:SW/2,y:SH-topInset-20};else if(this.n>=3)pp={x:this.arena.x/2,y:(this.arena.y+bottomInset)/2};else pp={x:22,y:this.arena.y+this.arena.h/2};
  const pause=new Sprite(Gfx.circle(16,white(0,.6),Theme.orange),32,32);pause.x=pp.x;pause.y=pp.y;pause.name='pause';pause.z=20;pause.alpha=.85;this.hud.add(pause);
  const pl=label('II',13,Theme.orange);pl.x=pp.x;pl.y=pp.y;pl.z=21;pl.alpha=.85;this.hud.add(pl);
  if(lay==='turns'&&this.n>1){const step=SW/this.n;this.seats.forEach(s=>{const l=label('',13,s.color);l.x=step*(s.index+.5);l.y=bottomInset+15;l.z=30;this.hud.add(l);this.turnLabels.push(l)});this.refreshTurnBoard()}
  if(this.duration>0){const w=lay==='zones'?SW-70:this.arena.w-40,y=lay==='zones'?this.bandY:this.arena.y+this.arena.h-8,x0=lay==='zones'?50:this.arena.x+20;
   const back=new Sprite(Gfx.pill(w,8,white(1,.12),null,4),w,8);back.ax=0;back.x=x0;back.y=y;this.hud.add(back);
   const bar=new Sprite(null,w,6,Theme.orange);bar.ax=0;bar.x=x0;bar.y=y;bar.z=1;this.hud.add(bar);this.timeBar=bar;this.timeBarWidth=w;
   if(lay==='arena'){back.y=this.arena.y+8;bar.y=this.arena.y+8}}}
 setActiveSeat(i){if(!this.seats.length)return;this.activeSeatIndex=Math.max(0,Math.min(this.seats.length-1,i));this.seats.forEach(s=>s.node.hidden=s.index!==this.activeSeatIndex);this.refreshTurnBoard();
  if(this.seats.length>1&&this.phase==='playing'){const s=this.seats[this.activeSeatIndex];s.banner(s.name.toUpperCase()+' IST DRAN',s.color,26,.9)}}
 refreshTurnBoard(){this.turnLabels.forEach((l,i)=>{if(i>=this.seats.length)return;const s=this.seats[i];l.text=s.name.slice(0,7).toUpperCase()+' '+s.score;l.alpha=i===this.activeSeatIndex?1:.5})}
 /* Juice: Hit-Stop, Kamera-Wackeln, Zeitlupe */
 hitStop(t){this.hitStopT=Math.max(this.hitStopT,t)}
 camShake(amt){amt=amt==null?6:amt;const w=this.world;w.removeAction('cam');w.x=0;w.y=0;const acts=[];for(let i=0;i<8;i++){const k=1-i/8;acts.push(A.moveTo((Math.random()*2-1)*amt*k,(Math.random()*2-1)*amt*k,.028))}acts.push(A.moveTo(0,0,.03));w.run(A.sequence(acts),'cam')}
 slowMo(scale,dur){this.timeScale=scale;this.slowT=dur}
 juiceScore(seat,v,old){if(this.phase!=='playing'||v<=old)return;const t=this.elapsed;
  if(t-(seat._lg||-9)>.12){seat._st=(t-(seat._lg||-9)<1.4)?(seat._st||0)+1:1;seat._lg=t;const st=seat._st,txt={3:'SERIE ×3',5:'ON FIRE ×5',8:'UNAUFHALTBAR ×8',12:'LEGENDE ×12'}[st];
   if(txt&&this.layout!=='turns'||txt&&this.n===1){seat.floatText(txt,{x:0,y:-seat.h*.18},st>=5?'#ff8a00':'#ffd98a',st>=8?26:20);Juice.haptic(st>=5?'heavy':'medium');if(st>=5)seat.flash(st>=8?'#ff8a00':'#ffd98a',.12,.25)}}
  if(this.n<2||this.layout==='turns'||this.elapsed<1.5)return;const sc=this.seats.map(s=>s.score),best=Math.max(...sc);if(sc.filter(x=>x===best).length>1)return;const li=sc.indexOf(best);
  if(li!==this.leader&&t-this.leadAt>1.6){const first=this.leader<0;this.leader=li;this.leadAt=t;if(!first){const s=this.seats[li];s.floatText('FÜHRUNG!',{x:0,y:s.h*.12},'#ffd98a',22);Juice.haptic('light')}}else if(li!==this.leader&&this.leader<0)this.leader=li}
 label(t,s,c){return label(t,s,c)}
 button(text,w,h,color,textColor,fontSize){const b=new Sprite(Gfx.pill(w,h,color,white(1,.6),Math.min(16,h/2)),w,h),l=label(text,fontSize||18,textColor||'#fff');l.z=1;b.add(l);return b}
 newRand(){return new Rand(this.sharedSeed)}
 makeBear(seat,height,faceRight){return new BearNode(seat.skin,height,!!faceRight)}
 burst(at,color,count,power){count=count==null?10:count;power=power==null?46:power;if(this.activeBursts>5)return;this.activeBursts++;
  for(let i=0;i<count;i++){const d=new Sprite(Gfx.dot(),6,6);d.color=i%3===0?'#fff':color;d.cbf=1;d.blend='add';d.x=at.x;d.y=at.y;d.z=450;this.add(d);const a=i/count*2*Math.PI+(Math.random()*.6-.3),dist=power*(.6+Math.random()*.6);
   d.run(A.sequence([A.group([A.moveBy(Math.cos(a)*dist,Math.sin(a)*dist,.4),A.fadeOut(.4),A.scaleTo(.2,.4)]),A.remove()]))}
  this.run(A.sequence([A.wait(.45),A.run(()=>{this.activeBursts--})]))}
 setScore(seat,v){const gained=v>seat.score,old=seat.score;seat.score=v;this.juiceScore(seat,v,old);if(this.layout==='turns')this.refreshTurnBoard();
  if(gained&&seat.scoreLabel&&seat.scoreLabel.parent){const p=seat.scoreLabel.parent.convert(seat.scoreLabel.x,seat.scoreLabel.y,this);this.burst(p,seat.color)}
  if(seat.scoreLabel){seat.scoreLabel.text=String(v);seat.scoreLabel.removeAllActions();seat.scoreLabel.run(A.sequence([A.scaleTo(1.35,.07),A.scaleTo(1,.1)]))}}
 addScore(seat,v){this.setScore(seat,seat.score+v)}
 addStat(key,v,seat){if(seat&&seat.isCPU)return;this.stats[key]=(this.stats[key]||0)+(v==null?1:v)}
 get aliveSeats(){return this.seats.filter(s=>s.alive)}
 get humansAlive(){return this.seats.some(s=>s.alive&&!s.isCPU)}
 flashAll(color,alpha){const f=new Sprite(null,SW,SH,color);f.ax=0;f.ay=0;f.alpha=alpha==null?.4:alpha;f.z=800;this.hud.add(f);f.run(A.sequence([A.fadeOut(.35),A.remove()]))}
 bannerAll(text,color,size,duration){color=color||Theme.orange;size=size==null?44:size;duration=duration==null?.8:duration;
  if(this.layout==='arena'){[0,Math.PI].forEach((rot,i)=>{if(i===1&&this.n<2)return;const l=label(text,size,color);l.x=this.arena.x+this.arena.w/2;l.y=this.arena.y+this.arena.h/2+(i===0?-40:40);l.rot=rot;l.z=700;l.setScale(.3);this.hud.add(l);l.run(A.sequence([A.scaleTo(1,.15),A.wait(duration),A.fadeOut(.2),A.remove()]))})}
  else this.seats.forEach(s=>s.banner(text,color,size,duration))}
 finishGame(scores,delay){if(this.finished)return;this.finished=true;this.phase='over';delay=delay==null?1:delay;const sc=scores||this.seats.map(s=>s.score),r={scores:sc,stats:this.stats},best=Math.max(...sc);this.slowMo(.35,.9);this.hitStop(.12);this.camShake(9);Juice.haptic('heavy');
  const srt=sc.slice().sort((a,b)=>b-a);if(this.n>=2&&srt[0]>0&&srt[0]!==srt[1]&&srt[0]-srt[1]<=Math.max(1,Math.abs(srt[0])*.05))this.run(A.sequence([A.wait(.5),A.run(()=>this.bannerAll('FOTOFINISH!','#ff8a00',30,.9))]));
  this.seats.forEach((s,i)=>{if(sc[i]===best){s.banner('SIEG!','#ffd98a',52,1.1);s.flash('#ffd98a',.35);s.burst({x:0,y:0},'#ffd98a',40,260);s.burst({x:0,y:0},'#fff',24,160)}});Sfx.play('horn');
  this.run(A.sequence([A.wait(delay+.6),A.run(()=>{this.onFinish&&this.onFinish(r)})]))}
 /* Takt: update -> Aktionen */
 tick(dt){if(this.userPaused||!this.built)return;
  if(this.hitStopT>0){this.hitStopT-=dt;this.world.step(0);return}
  if(this.slowT>0){this.slowT-=dt;if(this.slowT<=0)this.timeScale=1;dt*=this.timeScale}
  if(this.phase==='countdown'){this.countdownTime-=dt;const c=Math.ceil(this.countdownTime);if(c!==this.lastCount){this.lastCount=c;if(c>=1&&c<=3){this.bannerAll(String(c),'#f6e3b4',84,.6);this.flashAll('#d9ac5c',.12);Sfx.play('beep')}}
   if(this.countdownTime<=0){this.bannerAll('LOS!','#ffd98a',72,.6);this.flashAll('#ffd98a',.3);this.seats.forEach(q=>q.burst({x:0,y:0},'#ffd98a',22,200));Sfx.play('go');this.phase='playing';this.gameStarted()}}
  else if(this.phase==='playing'){this.elapsed+=dt;this.gameUpdate(dt);if(this.duration>0&&this.phase==='playing'){const left=Math.max(0,this.duration-this.elapsed);if(this.timeBar){this.timeBar.w=this.timeBarWidth*(left/this.duration);if(left<5){this.timeBar.color='rgb(255,0,0)';this.timeBar.sy=1+.5*Math.abs(Math.sin(left*Math.PI*2))}}
   if(left<5&&this.duration>=15){const ps=Math.ceil(left*2);if(ps!==this.pulseSec){this.pulseSec=ps;if(ps%2===0)Juice.haptic('light')}}const sc=Math.ceil(left);if(sc!==this.lastSec){this.lastSec=sc;if(sc>=1&&sc<=5&&this.duration>=15){Sfx.play('tick');if(sc<=3){this.bannerAll(String(sc),'rgba(255,217,138,.55)',64,.55);this.flashAll('#ff3b3b',.07)}}}if(left<=0)this.timeUp()}}
  this.step(dt)}
 seatFor(p){if(!this.seats.length)return null;if(this.layout==='turns')return this.seats[Math.min(this.activeSeatIndex,this.seats.length-1)];
  for(const s of this.seats){const z=s.zone;if(p.x>=z.x&&p.x<=z.x+z.w&&p.y>=z.y&&p.y<=z.y+z.h)return s}
  let best=this.seats[0],bd=1e9;for(const s of this.seats){const z=s.zone,cx=Math.max(z.x,Math.min(p.x,z.x+z.w)),cy=Math.max(z.y,Math.min(p.y,z.y+z.h)),d=Math.hypot(p.x-cx,p.y-cy);if(d<bd){bd=d;best=s}}return best}
 touchDown(id,pt){const pause=this.hud.child('pause');if(pause&&Math.hypot(pt.x-pause.x,pt.y-pause.y)<26){this.onPause&&this.onPause();return}
  const s=this.seatFor(pt);if(!s||s.isCPU)return;this.touchOwner[id]=s.index;if(this.phase==='playing'&&s.alive)this.began(s,s.local(pt),id)}
 touchMove(id,pt){const i=this.touchOwner[id];if(i==null)return;const s=this.seats[i];if(this.phase==='playing'&&s.alive)this.moved(s,s.local(pt),id)}
 touchUp(id,pt){const i=this.touchOwner[id];if(i==null)return;const s=this.seats[i];if(this.phase==='playing'&&s.alive)this.ended(s,s.local(pt),id);delete this.touchOwner[id]}
}

/* ---------- Juice: Vibration + automatische Effekte bei Toren ---------- */
const Juice={last:0,haptic(k){const now=performance.now();if(now-this.last<45)return;this.last=now;try{if(window.Haptic)k==='heavy'?Haptic.good():Haptic.tap(k)}catch(e){}}};
if(window.Sfx&&!Sfx._juiced){const _p=Sfx.play;Sfx._juiced=true;Sfx.play=function(name){_p.apply(Sfx,arguments);const sc=window.Arcade&&Arcade.scene;if(!sc||sc.phase!=='playing')return;
 if(name==='goal'){sc.hitStop(.09);sc.camShake(7);Juice.haptic('heavy')}else if(name==='hit'||name==='kick'||name==='stomp'||name==='save')Juice.haptic('light');else if(name==='miss'||name==='wrong'){try{window.Haptic&&Haptic.bad()}catch(e){}}}}
window.Juice=Juice;

/* ---------- Host ---------- */
const Arcade={SKC(){return SKC},setSH(v){SH=v;if(this.cv){const d=this.dpr||2;this.cv.width=Math.round(SW*d);this.cv.height=Math.round(SH*d)}},reg:{},scene:null,cv:null,c:null,raf:0,last:0,running:false,
 register(id,cls){this.reg[id]=cls},has(id){return!!this.reg[id]},
 mount(cv){this.cv=cv;const dpr=Math.min(Math.max(window.devicePixelRatio||1,2),3);cv.width=Math.round(SW*dpr);cv.height=Math.round(SH*dpr);this.c=cv.getContext('2d');this.dpr=dpr;
  const pt=e=>{const r=cv.getBoundingClientRect();return{x:(e.clientX-r.left)/r.width*SW,y:SH-(e.clientY-r.top)/r.height*SH}};
  cv.addEventListener('pointerdown',e=>{if(!this.scene)return;try{cv.setPointerCapture(e.pointerId)}catch(_){}e.preventDefault();window.Sfx&&Sfx.unlock();this.scene.touchDown(e.pointerId,pt(e))});
  cv.addEventListener('pointermove',e=>{if(!this.scene)return;e.preventDefault();this.scene.touchMove(e.pointerId,pt(e))});
  const up=e=>{if(!this.scene)return;this.scene.touchUp(e.pointerId,pt(e))};cv.addEventListener('pointerup',up);cv.addEventListener('pointercancel',up);
  cv.addEventListener('contextmenu',e=>e.preventDefault())},
 play(id,opts,onFinish,onPause){this.stop();const Cls=this.reg[id];const sc=new Cls();sc.configure(opts.seats,opts.difficulty);sc.onFinish=r=>{this.stop();onFinish(r)};sc.onPause=onPause;this.scene=sc;sc.build();this.running=true;this.last=performance.now();this.loop()},
 loop(){if(!this.running)return;this.raf=requestAnimationFrame(()=>this.loop());const now=performance.now();let dt=(now-this.last)/1000;this.last=now;if(dt<=0||dt>.05)dt=1/60;const sc=this.scene;if(!sc)return;sc.tick(dt);
  const c=this.c,d=this.dpr;c.setTransform(1,0,0,1,0,0);c.fillStyle=Theme.dark;c.fillRect(0,0,this.cv.width,this.cv.height);c.setTransform(this.cv.width/SW,0,0,-this.cv.height/SH,0,this.cv.height);c.globalAlpha=1;sc.draw(c)},
 pause(){if(this.scene)this.scene.userPaused=true},resume(){if(this.scene){this.scene.userPaused=false;this.last=performance.now()}},
 stop(){this.running=false;cancelAnimationFrame(this.raf);this.scene=null}};
window.SKC=SKC;window.MiniScene=MiniScene;window.BearNode=BearNode;window.Seat=Seat;window.Arcade=Arcade;
})();
