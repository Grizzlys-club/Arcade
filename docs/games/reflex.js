(()=>{
const {Node,Sprite,A,Gfx,Theme,rgba,white,label}=SK;
const ROUNDS=5,RED=rgba(.9,.12,.2),GREEN=rgba(.1,.9,.4),IDLE=rgba(.16,.17,.28);
class ReflexGame extends MiniScene{
 setupGame(){this.rand=this.newRand();this.round=0;this.states=[];this.stp='result';this.timer=0;this.goTime=0;this.order=[];this.bestHuman=0;this.ending=false;
  for(const s of this.seats){const st={dots:[],holding:false,released:false,locked:false,reactMs:0,cpuReact:0,cpuEarly:-1},pw=s.w-20,ph=s.h-74,py=-4;
   const pad=new Sprite(Gfx.pill(pw,ph,'#fff',white(1,.3),24),pw,ph);pad.color=IDLE;pad.cbf=1;pad.y=py;pad.z=2;s.field.add(pad);st.pad=pad;
   const glow=new Sprite(Gfx.glow(),pw*1.4,ph*1.25);glow.blend='add';glow.cbf=1;glow.alpha=0;glow.y=py;glow.z=1;s.field.add(glow);st.glow=glow;
   const rd=Math.min(pw,ph)*.42,ring=new Sprite(Gfx.circle(rd,white(1,.08),white(1,.7)),rd*2,rd*2);ring.y=py+10;ring.z=3;s.field.add(ring);ring.run(A.forever(A.sequence([A.scaleTo(1.06,.6),A.scaleTo(.96,.6)])),'pulse');
   st.title=label('FINGER DRAUF',Math.min(26,s.w*.1),'#fff');st.title.y=py+22;st.title.z=5;s.field.add(st.title);
   st.sub=label('Halten, bei GRÜN loslassen',Math.min(12,s.w*.06),white(1,.8));st.sub.y=py-8;st.sub.z=5;s.field.add(st.sub);
   st.ms=label('',Math.min(30,s.w*.14),'#fff');st.ms.y=py-42;st.ms.z=5;s.field.add(st.ms);
   for(let k=0;k<ROUNDS;k++){const d=new Sprite(Gfx.circle(5,'#fff'),10,10);d.color=white(.3);d.cbf=1;d.x=(k-2)*18;d.y=-s.h/2+12;d.z=3;s.field.add(d);st.dots.push(d)}
   this.states.push(st)}}
 gameStarted(){this.startRound()}
 startRound(){this.round++;this.stp='prep';this.timer=this.round===1?4:3;this.order=[];
  for(const s of this.seats){const st=this.states[s.index];st.released=false;st.locked=false;st.reactMs=0;st.holding=s.isCPU;st.ms.text='';st.pad.color=IDLE;st.glow.alpha=0;st.title.text=s.isCPU?'BEREIT':'FINGER DRAUF';st.sub.text=s.isCPU?'':'Halten, bei GRÜN loslassen';
   st.cpuReact=.19+(1-s.skill)*.3+Math.random()*.06;st.cpuEarly=Math.random()<.05*(1-s.skill)?.3+Math.random()*.7:-1}
  Sfx.play('tick')}
 beginWait(){this.stp='waiting';this.timer=1.5+this.rand.double()*2.5;
  for(const s of this.seats){const st=this.states[s.index];if(!st.holding)this.lockOut(s,'NICHT GEHALTEN');else{st.pad.color=RED;st.glow.color=RED;st.glow.alpha=.35;st.title.text='WARTEN…';st.sub.text='Noch nicht loslassen!'}}}
 lockOut(s,why){const st=this.states[s.index];if(st.locked||st.released)return;st.locked=true;st.pad.color=white(.18);st.glow.alpha=0;st.title.text=why===''?'ZU FRÜH!':why;st.sub.text='Gesperrt (0 Punkte)';st.dots[this.round-1].color=RED;s.shake();if(!s.isCPU){Sfx.play('wrong');Haptic.bad()}}
 gameUpdate(dt){
  if(this.stp==='prep'){this.timer-=dt;const humans=this.seats.filter(s=>!s.isCPU);if((humans.every(s=>this.states[s.index].holding)&&this.timer<(this.round===1?3.4:2.4))||this.timer<=0)this.beginWait()}
  else if(this.stp==='waiting'){this.timer-=dt;for(const s of this.seats){if(!s.isCPU)continue;const st=this.states[s.index];if(st.cpuEarly>=0){st.cpuEarly-=dt;if(st.cpuEarly<0)this.lockOut(s,'')}}if(this.timer<=0)this.goSignal()}
  else if(this.stp==='go'){const t=this.elapsed-this.goTime;for(const s of this.seats){if(!s.isCPU)continue;const st=this.states[s.index];if(!st.released&&!st.locked&&t>=st.cpuReact)this.release(s)}
   if(t>1.6||this.seats.every(s=>this.states[s.index].released||this.states[s.index].locked))this.showResult()}
  else{this.timer-=dt;if(this.timer<=0&&!this.ending){if(this.round>=ROUNDS){this.ending=true;if(this.bestHuman>0)this.stats.reaction=this.bestHuman;this.finishGame()}else this.startRound()}}
  if(this.stp==='waiting'&&this.seats.every(s=>this.states[s.index].locked))this.showResult()}
 goSignal(){this.stp='go';this.goTime=this.elapsed;Sfx.play('go');for(const s of this.seats){const st=this.states[s.index];if(st.locked)continue;st.pad.color=GREEN;st.glow.color=GREEN;st.glow.alpha=.95;st.title.text='LOS!';st.sub.text='LOSLASSEN!';st.pad.run(A.sequence([A.scaleTo(1.04,.05),A.scaleTo(1,.1)]));if(!s.isCPU)Haptic.tap()}}
 release(s){const st=this.states[s.index];if(st.released||st.locked)return;st.released=true;const ms=Math.round((this.elapsed-this.goTime)*1000);st.reactMs=ms;this.order.push(s.index);const place=this.order.length;
  st.ms.text=ms+' ms';st.title.text=place===1?'ERSTER!':place+'. PLATZ';st.sub.text=ms<250?'Blitzschnell!':(ms<350?'Stark!':'Geht schneller…');st.glow.alpha=.4;s.burst({x:0,y:0},place===1?'#ff0':s.color,place===1?20:8);
  if(!s.isCPU){Sfx.play(place===1?'right':'tap');Haptic.good();if(this.bestHuman===0||ms<this.bestHuman)this.bestHuman=ms}}
 showResult(){if(this.stp==='result')return;this.stp='result';this.timer=1.7;const table=this.n===2?[3,1]:[3,2,1];
  this.order.forEach((idx,k)=>{const s=this.seats[idx],pts=k<table.length?table[k]:0;this.states[idx].dots[this.round-1].color=k===0?'#ff0':s.color;if(pts>0){this.addScore(s,pts);s.floatText('+'+pts,{x:0,y:50},'#ff0',30)}});
  for(const s of this.seats){const st=this.states[s.index];if(!st.released&&!st.locked){st.title.text='VERPASST';st.sub.text='';st.pad.color=white(.25);st.glow.alpha=0}}}
 began(seat){const st=this.states[seat.index];if(this.stp==='prep'&&!st.holding){st.holding=true;st.pad.color=rgba(.3,.3,.5);st.title.text='GUT – HALTEN';st.sub.text='Warte auf die anderen…';Sfx.play('tap');Haptic.tap()}}
 ended(seat){const st=this.states[seat.index];if(!st.holding)return;st.holding=false;
  if(this.stp==='prep'){st.pad.color=IDLE;st.title.text='FINGER DRAUF';st.sub.text='Halten, bei GRÜN loslassen'}else if(this.stp==='waiting')this.lockOut(seat,'');else if(this.stp==='go')this.release(seat)}
}
Arcade.register('reflex',ReflexGame);
})();
