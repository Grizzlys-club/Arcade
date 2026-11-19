(()=>{
const {Node,Sprite,A,Gfx,Theme,rgba,white,label}=SK;
const ROUNDS=5;
const gauss=()=>{const u1=Math.max(1e-9,Math.random()),u2=Math.random();return Math.sqrt(-2*Math.log(u1))*Math.cos(2*Math.PI*u2)};
class StopTimeGame extends MiniScene{
 setupGame(){const r=this.newRand();this.targets=r.shuffled([2,3,4,5,6,7]).slice(0,ROUNDS);this.round=0;this.stp='intro';this.t=0;this.states=[];
  for(const s of this.seats){const st={tapped:false,stopT:0,cpuT:0},w=s.w,h=s.h,pw=w-20,ph=h-56,py=-14;
   const panel=new Sprite(Gfx.pill(pw,ph,white(.08,.9),s.color.replace(/[\d.]+\)$/,'.5)'),22,false),pw,ph);panel.y=py;panel.z=1;s.field.add(panel);st.panel=panel;
   const glow=new Sprite(Gfx.glow(),pw*1.3,ph*.7);glow.blend='add';glow.color=s.color;glow.cbf=1;glow.alpha=.25;glow.y=py+10;glow.z=2;s.field.add(glow);st.glow=glow;
   const cap=label('ZIELZEIT',Math.min(12,w*.06),white(1,.6));cap.y=py+ph/2-24;cap.z=5;s.field.add(cap);
   const tg=label('',Math.min(44,w*.2),Theme.orange);tg.y=py+ph/2-58;tg.z=5;s.field.add(tg);st.target=tg;
   const clock=label('0.00',Math.min(64,w*.3),'#fff');clock.y=py+8;clock.z=5;s.field.add(clock);st.clock=clock;
   const err=label('',Math.min(22,w*.11),'#fff');err.y=py-38;err.z=5;s.field.add(err);st.err=err;
   const sub=label('',Math.min(13,w*.065),white(1,.8));sub.y=py-62;sub.z=5;s.field.add(sub);st.sub=sub;
   const rl=label('RUNDE 1/'+ROUNDS,11,white(1,.5));rl.y=py+ph/2-8;rl.z=5;s.field.add(rl);st.round=rl;
   const bw=pw-40,btn=this.button('STOPP',bw,46,s.color,'#fff',Math.min(22,w*.1));btn.y=py-ph/2+36;btn.z=6;s.field.add(btn);st.button=btn;this.states.push(st)}}
 gameStarted(){this.startRound()}
 startRound(){this.stp='intro';this.t=1.4;const target=this.targets[this.round];
  for(const s of this.seats){const st=this.states[s.index];st.tapped=false;st.stopT=0;st.target.text=target.toFixed(2)+' s';st.target.setScale(1.6);st.target.run(A.scaleTo(1,.2));
   st.clock.text='0.00';st.clock.color=white(1,.45);st.clock.alpha=1;st.err.text='';st.sub.text="GLEICH GEHT'S LOS …";st.round.text='RUNDE '+(this.round+1)+'/'+ROUNDS;st.button.alpha=.35;st.glow.color=s.color;st.glow.alpha=.25;
   if(s.isCPU)st.cpuT=Math.max(.4,target+gauss()*(.04+.3*(1-s.skill)))}
  Sfx.play('tick')}
 beginRun(){this.stp='run';this.t=0;for(const s of this.seats){const st=this.states[s.index];st.clock.color='#fff';st.sub.text=this.round===0?'TIPPEN BEI ZIELZEIT':'UHR VERSCHWINDET …';st.button.alpha=1}Sfx.play('go')}
 gameUpdate(dt){
  if(this.stp==='intro'){this.t-=dt;if(this.t<=0)this.beginRun()}
  else if(this.stp==='run'){this.t+=dt;const target=this.targets[this.round];
   for(const s of this.seats){const st=this.states[s.index];if(st.tapped)continue;
    if(this.t<1)st.clock.text=this.t.toFixed(2);else if(st.clock.text!=='?.??'){st.clock.text='?.??';st.clock.color=white(1,.5);st.clock.run(A.sequence([A.fadeTo(.2,.2),A.fadeTo(.8,.2)]));st.sub.text='UHR VERSTECKT'}
    if(s.isCPU&&this.t>=st.cpuT)this.stop(s)}
   if(this.seats.every(s=>this.states[s.index].tapped)||this.t>target+2.5)this.beginReveal()}
  else{this.t-=dt;if(this.t<=0&&this.phase==='playing'){this.round++;if(this.round>=ROUNDS)this.finishGame();else this.startRound()}}}
 stop(s){const st=this.states[s.index];if(this.stp!=='run'||st.tapped)return;st.tapped=true;st.stopT=this.t;const target=this.targets[this.round],e=this.t-target,ae=Math.abs(e),
  pts=ae<.1?5:(ae<.25?3:(ae<.5?1:0)),col=ae<.1?Theme.green:(ae<.25?'#ff0':(ae<.5?Theme.orange:rgba(1,.3,.3)));
  st.clock.removeAllActions();st.clock.alpha=1;st.clock.text=this.t.toFixed(2);st.clock.color=col;st.clock.setScale(1.3);st.clock.run(A.scaleTo(1,.2));
  st.err.text=(e>=0?'+':'−')+ae.toFixed(2)+' s';st.err.color=col;st.sub.text=pts===5?'PERFEKT!':(pts>0?'GESTOPPT':'ZU WEIT DANEBEN');st.button.alpha=.25;st.glow.color=col;st.glow.alpha=.6;
  if(pts>0){this.addScore(s,pts);this.addStat('hits',1,s);s.floatText('+'+pts,{x:0,y:40},col,pts===5?34:26);s.burst({x:0,y:-6},col,pts===5?24:10)}
  if(!s.isCPU){Sfx.play(pts>=3?'right':(pts>0?'tap':'miss'));if(pts>0)Haptic.good();else Haptic.bad()}}
 beginReveal(){if(this.stp==='reveal')return;this.stp='reveal';this.t=1.6;
  for(const s of this.seats){const st=this.states[s.index];if(!st.tapped){st.clock.text=this.targets[this.round].toFixed(2);st.clock.color=white(1,.5);st.sub.text='ZU SPÄT';st.err.text='';st.button.alpha=.15}}}
 began(seat){this.stop(seat)}
}
Arcade.register('stoptime',StopTimeGame);
})();
