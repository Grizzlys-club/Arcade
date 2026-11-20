(()=>{
const {Node,Sprite,A,Gfx,Theme,rgba,white,label}=SK;
const THROWS=6,AMP=1.15,OMEGA=2.8;
const gauss=()=>{const u1=Math.max(1e-9,Math.random()),u2=Math.random();return Math.sqrt(-2*Math.log(u1))*Math.cos(2*Math.PI*u2)};
class PendulumGame extends MiniScene{
 ballPos(phi){const th=AMP*Math.sin(phi);return{x:this.pivot.x+this.len*Math.sin(th),y:this.pivot.y-this.len*Math.cos(th)}}
 landing(phi){const th=AMP*Math.sin(phi),c=Math.cos(phi),sg=c>=0?1:-1;let dx=sg*Math.cos(th),dy=sg*Math.sin(th)+.9;const l=Math.hypot(dx,dy);dx/=l;dy/=l;const f=.35+.65*Math.abs(c),p=this.ballPos(phi);return{x:p.x+dx*f*this.dmax,y:p.y+dy*f*this.dmax}}
 setupGame(){const s0=this.seats[0],w=s0.w,h=s0.h;this.len=Math.min(64,w*.27);this.ringR=Math.min(44,w*.2);this.dmax=h*.7;this.pivot={x:0,y:-h/2+this.len+18};this.states=[];this.targetPhis=[];this.finishedCalled=false;
  const r=this.newRand();for(let i=0;i<THROWS;i++){let chosen=.9;for(let k=0;k<80;k++){const phi=r.range(0,2*Math.PI),p=this.landing(phi);if(p.y>this.pivot.y+70&&p.y<h/2-44&&Math.abs(p.x)<w/2-this.ringR-6){chosen=phi;break}}this.targetPhis.push(chosen)}
  const R=this.ringR;
  for(const s of this.seats){const st={idx:0,mode:0,phase:0,timer:0,tapPhase:0,target:new Node()};
   for(let i=0;i<=14;i++){const phi=-Math.PI/2+Math.PI*i/14,d=new Sprite(Gfx.dot(),4,4);const p=this.ballPos(phi);d.x=p.x;d.y=p.y;d.color=s.color;d.cbf=1;d.alpha=.3;d.z=1;s.field.add(d)}
   st.target.z=2;[1,.6,.28].forEach((f,k)=>{const ring=new Sprite(Gfx.circle(R,'#fff'),R*2*f,R*2*f);ring.color=k===2?Theme.orange:s.color;ring.cbf=1;ring.alpha=k===2?.95:(k===0?.28:.5);ring.z=k;st.target.add(ring)});
   const tg=new Sprite(Gfx.glow(),R*3.4,R*3.4);tg.blend='add';tg.color=s.color;tg.cbf=1;tg.alpha=.6;tg.z=-1;st.target.add(tg);st.targetGlow=tg;
   // pulsierender Zielring (Extra)
   const pul=new Sprite(Gfx.circle(R,'rgba(0,0,0,0)',s.color),R*2,R*2);pul.blend='add';pul.z=3;pul.run(A.forever(A.sequence([A.group([A.scaleTo(1.25,.7),A.fadeTo(0,.7)]),A.group([A.scaleTo(1,0),A.fadeTo(.7,0)])])));st.target.add(pul);
   st.target.alpha=0;s.field.add(st.target);
   const rope=new Sprite(null,2.5,this.len,white(1,.85));rope.ay=1;rope.x=this.pivot.x;rope.y=this.pivot.y;rope.z=4;s.field.add(rope);st.rope=rope;
   const pv=new Sprite(Gfx.circle(5,'#fff'),10,10);pv.x=this.pivot.x;pv.y=this.pivot.y;pv.color=s.color;pv.cbf=1;pv.z=5;s.field.add(pv);
   const br=Math.max(9,Math.min(13,s.w*.05)),ball=new Sprite(Gfx.ball(br),br*2,br*2);const bp=this.ballPos(0);ball.x=bp.x;ball.y=bp.y;ball.z=20;s.field.add(ball);
   const g=new Sprite(Gfx.glow(),br*5,br*5);g.blend='add';g.color=Theme.orange;g.cbf=1;g.alpha=.7;g.z=-1;ball.add(g);st.ball=ball;
   const bear=this.makeBear(s,38,true);bear.x=-s.w/2+34;bear.y=-s.h/2+4;bear.z=3;bear.alpha=.85;s.field.add(bear);
   const cnt=label('WURF 1/'+THROWS,11,white(1,.6));cnt.ha='right';cnt.x=s.w/2-12;cnt.y=-s.h/2+12;cnt.z=6;s.field.add(cnt);st.counter=cnt;
   const hint=label(s.isCPU?'':'TIPPEN = WERFEN',Math.min(15,s.w*.075),'#fff');hint.y=this.pivot.y+38;hint.z=30;s.field.add(hint);hint.run(A.sequence([A.wait(4),A.fadeOut(.5)]));st.hint=hint;
   this.states.push(st)}}
 gameStarted(){for(const s of this.seats)this.startThrow(s)}
 startThrow(s){const st=this.states[s.index];st.mode=0;st.phase=0;st.timer=0;st.ball.removeAllActions();st.ball.setScale(1);st.ball.alpha=1;const bp=this.ballPos(0);st.ball.x=bp.x;st.ball.y=bp.y;st.rope.alpha=1;st.rope.rot=0;
  st.counter.text='WURF '+(st.idx+1)+'/'+THROWS;const lp=this.landing(this.targetPhis[st.idx]);st.target.x=lp.x;st.target.y=lp.y;st.target.setScale(.2);st.target.alpha=0;
  st.target.run(A.group([A.fadeIn(.15),A.sequence([A.scaleTo(1.15,.18),A.scaleTo(1,.1)])]));
  if(s.isCPU){const err=gauss()*(1-s.skill)*.3;st.tapPhase=Math.max(.05,this.targetPhis[st.idx]+err)}}
 gameUpdate(dt){let allDone=true;
  for(const s of this.seats){const st=this.states[s.index];
   if(st.mode===0){allDone=false;st.phase+=OMEGA*dt;st.timer+=dt;st.rope.rot=AMP*Math.sin(st.phase);const bp=this.ballPos(st.phase);st.ball.x=bp.x;st.ball.y=bp.y;
    if(s.isCPU){if(st.phase>=st.tapPhase)this.release(s)}else if(st.timer>5)this.release(s)}
   else if(st.mode===1)allDone=false;
   else if(st.mode===2){allDone=false;st.timer-=dt;if(st.timer<=0){st.idx++;if(st.idx>=THROWS){st.mode=3;st.ball.run(A.fadeOut(.3));st.target.run(A.fadeOut(.3));st.counter.text='FERTIG'}else this.startThrow(s)}}}
  if(allDone&&!this.finishedCalled){this.finishedCalled=true;this.finishGame()}}
 release(s){const st=this.states[s.index];if(st.mode!==0)return;st.mode=1;const land=this.landing(st.phase);st.hint.removeAllActions();st.hint.alpha=0;st.rope.run(A.fadeTo(.2,.15));Sfx.play('kick');if(!s.isCPU)Haptic.tap('medium');
  st.ball.run(A.group([SK.easeOut(A.moveTo(land.x,land.y,.5)),A.sequence([A.scaleTo(1.6,.25),A.scaleTo(1,.25)])]));
  const color=s.color;st.ball.run(A.repeat(A.sequence([A.run(()=>{const d=new Sprite(Gfx.dot(),8,8);d.color=color;d.cbf=1;d.blend='add';d.x=st.ball.x;d.y=st.ball.y;d.z=15;s.field.add(d);d.run(A.sequence([A.group([A.fadeOut(.3),A.scaleTo(.2,.3)]),A.remove()]))}),A.wait(.05)]),10));
  this.run(A.sequence([A.wait(.5),A.run(()=>this.landed(s,land))]))}
 landed(s,p){const st=this.states[s.index];if(st.mode!==1||this.phase!=='playing')return;const d=Math.hypot(p.x-st.target.x,p.y-st.target.y),R=this.ringR,pts=d<R*.28?5:(d<R*.6?3:(d<R?1:0));st.mode=2;st.timer=.9;
  if(pts>0){this.addScore(s,pts);this.addStat('hits',1,s);s.floatText('+'+pts,{x:p.x,y:p.y+24},pts===5?'#ff0':'#fff',pts===5?34:26);s.burst(p,pts===5?'#ff0':s.color,pts===5?30:12,pts===5?160:100);
   st.targetGlow.run(A.sequence([A.fadeTo(1,.05),A.fadeTo(.6,.3)]));st.target.run(A.sequence([A.scaleTo(1.25,.07),A.scaleTo(1,.12)]));
   if(!s.isCPU){Sfx.play(pts===5?'goal':'right');Haptic.good()}if(pts===5){s.banner('VOLLTREFFER!','#ff0',28,.5);s.shake(4);s.flash('#ff0',.2)}}
  else{s.floatText('DANEBEN',{x:p.x,y:p.y+24},white(1,.8),18);s.burst(p,white(.7),5,50);if(!s.isCPU){Sfx.play('miss');Haptic.bad()}}}
 began(seat){this.release(seat)}
}
Arcade.register('pendulum',PendulumGame);
})();
