(()=>{
const {Node,Sprite,A,Gfx,Theme,rgba,white,label}=SK;
const ROUNDS=5,RED=rgba(.85,.12,.18),GREEN=rgba(.1,.85,.35);
class ReactionGame extends MiniScene{
 setupGame(){this.rand=this.newRand();this.round=0;this.states=[];this.stp='result';this.timer=0;this.goTime=0;this.order=[];this.bestHuman=0;this.roundLabels=[];
  for(const s of this.seats){const st={tapped:false,locked:false,reactMs:0,cpuReact:0,cpuEarly:-1},pw=s.w-20,ph=s.h-56,py=-14;
   const panel=new Sprite(Gfx.pill(pw,ph,'#fff',null,22),pw,ph);panel.color=white(.25);panel.cbf=1;panel.y=py;panel.z=2;s.field.add(panel);st.panel=panel;
   const glow=new Sprite(Gfx.glow(),pw*1.4,ph*1.2);glow.blend='add';glow.alpha=0;glow.cbf=1;glow.y=py;glow.z=1;s.field.add(glow);st.glow=glow;
   st.title=label('BEREIT?',Math.min(40,s.w*.16),'#fff');st.title.y=py+20;st.title.z=5;s.field.add(st.title);
   st.sub=label('Tippe, wenn es grün wird',Math.min(14,s.w*.065),white(1,.8));st.sub.y=py-16;st.sub.z=5;s.field.add(st.sub);
   st.ms=label('',Math.min(30,s.w*.13),'#fff');st.ms.y=py-56;st.ms.z=5;s.field.add(st.ms);
   st.cross=label('✕',Math.min(120,s.w*.5),white(1,.9));st.cross.y=py;st.cross.z=6;st.cross.alpha=0;s.field.add(st.cross);
   const bh=Math.min(60,s.h*.16),bear=this.makeBear(s,bh,true);bear.x=-pw/2+bh*.75;bear.y=py-ph/2+8;bear.z=4;bear.alpha=.9;s.field.add(bear);
   const rl=label('RUNDE 1/'+ROUNDS,11,white(1,.6));rl.ha='right';rl.x=pw/2-12;rl.y=py-ph/2+14;rl.z=5;s.field.add(rl);this.roundLabels.push(rl);this.states.push(st)}}
 gameStarted(){this.startRound()}
 startRound(){this.round++;this.stp='waiting';this.order=[];this.timer=1.4+this.rand.double()*2.8;
  for(const s of this.seats){const st=this.states[s.index];st.tapped=false;st.locked=false;st.reactMs=0;st.panel.color=RED;st.glow.color=RED;st.glow.alpha=.35;st.title.text='WARTEN…';st.sub.text='Noch nicht tippen!';st.ms.text='';st.cross.alpha=0;this.roundLabels[s.index].text='RUNDE '+this.round+'/'+ROUNDS;
   if(s.isCPU){st.cpuReact=(180+(1-s.skill)*270+Math.random()*60)/1000;st.cpuEarly=Math.random()<.06*(1-s.skill)?.3+Math.random()*(Math.max(.4,this.timer-.1)-.3):-1}}
  Sfx.play('tick')}
 gameUpdate(dt){
  if(this.stp==='waiting'){this.timer-=dt;for(const s of this.seats){if(!s.isCPU)continue;const st=this.states[s.index];if(st.cpuEarly>=0){st.cpuEarly-=dt;if(st.cpuEarly<0)this.falseStart(s)}}if(this.timer<=0)this.goSignal()}
  else if(this.stp==='go'){const t=this.elapsed-this.goTime;for(const s of this.seats){if(!s.isCPU)continue;const st=this.states[s.index];if(!st.tapped&&!st.locked&&t>=st.cpuReact)this.hit(s)}
   if(t>1.6||this.seats.every(s=>this.states[s.index].tapped||this.states[s.index].locked))this.showResult()}
  else{this.timer-=dt;if(this.timer<=0&&this.phase==='playing'){if(this.round>=ROUNDS){if(this.bestHuman>0)this.stats.reaction=this.bestHuman;this.finishGame()}else this.startRound()}}}
 goSignal(){this.stp='go';this.goTime=this.elapsed;Sfx.play('go');for(const s of this.seats){const st=this.states[s.index];if(st.locked)continue;st.panel.color=GREEN;st.glow.color=GREEN;st.glow.alpha=.9;st.title.text='JETZT!';st.sub.text='TIPPEN!';st.panel.run(A.sequence([A.scaleTo(1.04,.05),A.scaleTo(1,.1)]))}}
 falseStart(s){const st=this.states[s.index];if(st.locked||st.tapped)return;st.locked=true;st.panel.color=white(.2);st.glow.alpha=0;st.title.text='ZU FRÜH!';st.sub.text='Gesperrt für diese Runde';st.cross.alpha=1;st.cross.color=RED;st.cross.setScale(1.4);st.cross.run(A.scaleTo(1,.15));s.shake();
  if(!s.isCPU){Sfx.play('wrong');Haptic.bad()}if(this.seats.every(x=>this.states[x.index].locked))this.showResult()}
 hit(s){const st=this.states[s.index];if(st.tapped||st.locked)return;st.tapped=true;const ms=Math.round((this.elapsed-this.goTime)*1000);st.reactMs=ms;this.order.push(s.index);const place=this.order.length;
  st.ms.text=ms+' ms';st.title.text=place===1?'ERSTER!':place+'. PLATZ';st.sub.text=ms<250?'Blitzschnell!':(ms<350?'Stark!':'Geht schneller…');s.burst({x:0,y:-14},place===1?'#ff0':s.color,place===1?18:8);
  if(!s.isCPU){Sfx.play(place===1?'right':'tap');Haptic.good();if(this.bestHuman===0||ms<this.bestHuman)this.bestHuman=ms}}
 showResult(){if(this.stp==='result')return;this.stp='result';this.timer=1.6;const table=this.n===2?[3,1]:[3,2,1,0];
  this.order.forEach((idx,k)=>{const s=this.seats[idx],pts=k<table.length?table[k]:0;if(pts>0){this.addScore(s,pts);s.floatText('+'+pts,{x:0,y:40},'#ff0',30)}});
  for(const s of this.seats){const st=this.states[s.index];if(!st.tapped&&!st.locked){st.title.text='VERPASST';st.sub.text='';st.panel.color=white(.25);st.glow.alpha=0}}}
 began(seat){if(this.stp==='waiting')this.falseStart(seat);else if(this.stp==='go')this.hit(seat)}
}
Arcade.register('reaction',ReactionGame);
})();
