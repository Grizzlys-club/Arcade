(()=>{
const {Node,Sprite,A,Gfx,Theme,rgba,white,label}=SK;
const Skin=id=>META.SKINS.find(k=>k.id===id);
const TOTAL=8,rr=(a,b)=>a+Math.random()*(b-a);
class PowerShotGame extends MiniScene{
 static get layout(){return 'turns'}
 setupGame(){this.duration=0;this.turnWait=0;this.st=[];
  for(const s of this.seats){const o={rand:this.newRand(),m:0,dir:1,speed:.8,center:.5,width:.2,shot:0,locked:false,done:false,waitTimer:0,cpuTarget:.5,cpuArmed:0,idle:0,dots:[]};this.st.push(o);const w=s.w,h=s.h,scale=Math.min(1,w/300),sc=Math.max(.85,scale);
   const floor=new Sprite(Gfx.texture('power_floor'+Math.floor(w)+'x'+Math.floor(h),w,h,1,c=>{Gfx.gradientColors(c,rgba(.16,.12,.04,.85),rgba(.06,.05,.08,.9),w,h);c.strokeStyle='rgba(255,255,255,.08)';c.lineWidth=2;c.beginPath();c.arc(w/2,h*.4,w*.3,0,7);c.stroke()}),w,h);floor.z=-10;s.field.add(floor);
   o.goalW=Math.min(w*.7,210);o.goalH=Math.max(44,o.goalW*.36);o.goalY=h/2-42-o.goalH;const g=new Sprite(Gfx.goal(o.goalW,o.goalH),o.goalW+16,o.goalH+12);g.y=o.goalY+o.goalH/2-2;g.z=2;s.field.add(g);o.goal=g;
   const k=new BearNode(Skin(s.skin.id==='galaxy'?'classic':'galaxy'),o.goalH*.75,false);k.y=o.goalY-4;k.z=4;k.startBob(2,.3);s.field.add(k);o.keeper=k;
   o.meterW=w-44;o.meterY=-h/2+44;const back=new Sprite(Gfx.pill(o.meterW+8,30,white(0,.6),white(1,.4),15),o.meterW+8,30);back.y=o.meterY;back.z=10;s.field.add(back);
   const bw=Math.floor(o.meterW),bar=new Sprite(Gfx.texture('power_bar'+bw,bw,20,2,c=>{c.save();SK.rr(c,0,0,bw,20,10);c.clip();const gr=c.createLinearGradient(0,0,bw,0);gr.addColorStop(0,'rgb(230,38,51)');gr.addColorStop(.5,'rgb(255,191,26)');gr.addColorStop(1,'rgb(230,38,51)');c.fillStyle=gr;c.fillRect(0,0,bw,20);c.restore()}),o.meterW,20);bar.y=o.meterY;bar.z=11;s.field.add(bar);
   o.green=new Sprite(null,10,20,rgba(.2,1,.35,.9));o.green.z=12;o.green.y=o.meterY;s.field.add(o.green);
   o.perfect=new Sprite(null,3,20,'#fff');o.perfect.z=13;o.perfect.y=o.meterY;o.perfect.alpha=.9;s.field.add(o.perfect);
   o.marker=new Sprite(Gfx.pill(8,36,'#fff',s.color,4),8,36);o.marker.z=14;o.marker.y=o.meterY;s.field.add(o.marker);
   const mg=new Sprite(Gfx.glow(),34,50);mg.color=s.color;mg.cbf=1;mg.blend='add';mg.alpha=.7;mg.z=-1;o.marker.add(mg);
   o.ballRest={x:0,y:o.meterY+50*sc};o.ball=new Sprite(Gfx.ball(14),20*sc,20*sc);o.ball.x=o.ballRest.x;o.ball.y=o.ballRest.y;o.ball.z=8;s.field.add(o.ball);
   const shooter=this.makeBear(s,40*sc,true);shooter.x=-26*sc;shooter.y=o.ballRest.y-18;shooter.z=7;s.field.add(shooter);
   const sl=label('SCHUSS 1/'+TOTAL,13,white(1,.7));sl.ha='left';sl.x=-w/2+14;sl.y=h/2-34;sl.z=400;s.node.add(sl);o.shotLabel=sl;
   const ds=Math.min(12,(w-40)/TOTAL-4);for(let i=0;i<TOTAL;i++){const d=new Sprite(Gfx.circle(8,white(1,.15)),ds,ds),total=TOTAL*(ds+4);d.x=-total/2+(ds+4)*(i+.5);d.y=o.meterY+24;d.z=10;s.field.add(d);o.dots.push(d)}
   if(!s.isCPU){const hint=new Node(),l=label('TIPPEN IM GRÜNEN!',15,rgba(.3,1,.45));l.y=o.ballRest.y+40;hint.add(l);hint.z=50;hint.run(A.forever(A.sequence([A.fadeTo(.4,.4),A.fadeTo(1,.4)])));s.field.add(hint);o.hint=hint}
   this.newShot(s,o)}
  this.setActiveSeat(0)}
 newShot(s,o){const r=o.rand;o.locked=false;o.width=Math.max(.07,.22-o.shot*.019);o.center=r.range(.15+o.width/2,.85-o.width/2);o.speed=.75+o.shot*.13;o.m=r.range(0,1);o.dir=r.chance(.5)?1:-1;
  o.green.w=o.width*o.meterW;o.green.x=-o.meterW/2+o.center*o.meterW;o.perfect.x=o.green.x;o.shotLabel.text='SCHUSS '+Math.min(TOTAL,o.shot+1)+'/'+TOTAL;
  o.ball.removeAllActions();o.ball.x=o.ballRest.x;o.ball.y=o.ballRest.y;o.ball.setScale(1);o.ball.alpha=1;o.keeper.x=0;
  const err=(Math.random()*2-1)*(1.05-s.skill)*.2+rr(-.015,.015);o.cpuTarget=Math.max(.01,Math.min(.99,o.center+err));o.cpuArmed=rr(.5,1.1);o.idle=0}
 began(seat){this.tap(seat,this.st[seat.index])}
 tap(s,o){if(o.locked||o.done||this.phase!=='playing')return;o.locked=true;if(o.hint){o.hint.run(A.sequence([A.fadeOut(.2),A.remove()]));o.hint=null}
  const d=Math.abs(o.m-o.center),half=o.width/2;let pts;if(d<=half)pts=10-Math.floor((d/half)*3.99);else pts=Math.max(0,6-Math.floor((d-half)*22));pts=Math.max(0,Math.min(10,pts));
  this.addScore(s,pts);if(pts>=7)this.addStat('goals',1,s);o.marker.run(A.sequence([A.scaleYTo(1.4,.06),A.scaleYTo(1,.1)]));
  const dc=pts>=10?'#ff0':(pts>=7?rgba(.3,1,.4):(pts>=4?'#f90':'#f00'));if(o.shot<o.dots.length){o.dots[o.shot].texture=Gfx.circle(8,dc);o.dots[o.shot].run(A.sequence([A.scaleTo(1.5,.08),A.scaleTo(1,.12)]))}
  this.animateShot(s,o,pts);o.shot++;o.waitTimer=1.25;Sfx.play('kick');if(!s.isCPU)Haptic.tap('heavy')}
 animateShot(s,o,pts){const side=Math.random()<.5?1:-1;let target,text,color=s.color,after=A.fadeOut(.2),kx=0;
  if(pts>=10){target={x:side*(o.goalW/2-12),y:o.goalY+o.goalH-12};text='TRAUMTOR! +'+pts;color='#ff0';kx=-side*o.goalW*.25}
  else if(pts>=7){target={x:side*o.goalW*.3,y:o.goalY+o.goalH*.35};text='TOR! +'+pts;kx=-side*o.goalW*.2}
  else if(pts>=4){target={x:side*o.goalW/2,y:o.goalY+o.goalH*.5};text='PFOSTEN +'+pts;color='#f90';kx=side*o.goalW*.1;after=A.sequence([A.moveBy(-side*40,-50,.3),A.fadeOut(.15)])}
  else{target={x:side*(o.goalW/2+40),y:o.goalY+o.goalH+30};text=pts>0?'DANEBEN +'+pts:'DANEBEN';color=white(.8);kx=0}
  o.ball.run(A.sequence([A.group([SK.easeOut(A.moveTo(target.x,target.y,.32)),A.scaleTo(.65,.32),A.rotateBy(8,.32)]),A.run(()=>{
   s.floatText(text,{x:0,y:o.goalY-26},color,18);
   if(pts>=7){s.burst(target,color,pts>=10?30:16,140);o.goal.run(A.sequence([A.moveBy(0,4,.05),A.moveBy(0,-4,.08)]));Sfx.play(pts>=10?'goal':'right');if(pts>=10){s.shake(5);s.flash('#ff0',.18)}}
   else if(pts>=4)Sfx.play('hit');else Sfx.play('miss')}),after]));
  o.keeper.run(SK.easeOut(A.moveToX(kx,.25)))}
 advanceTurn(){for(let k=1;k<=Math.max(1,this.n);k++){const j=(this.activeSeatIndex+k)%this.n;if(!this.st[j].done){this.st[j].idle=0;this.st[j].cpuArmed=.6;this.setActiveSeat(j);return}}}
 gameUpdate(dt){for(const s of this.seats){if(s.index!==this.activeSeatIndex)continue;const o=this.st[s.index];if(o.done)continue;
   if(o.locked){o.waitTimer-=dt;if(o.waitTimer<=0){if(o.shot>=TOTAL){o.done=true;o.marker.alpha=.3;s.banner('FERTIG',s.color,34,1)}else this.newShot(s,o)}continue}
   const prev=o.m;o.m+=o.dir*o.speed*dt;if(o.m>1){o.m=2-o.m;o.dir=-1}if(o.m<0){o.m=-o.m;o.dir=1}o.marker.x=-o.meterW/2+o.m*o.meterW;o.idle+=dt;
   if(!s.isCPU&&o.idle>7){this.tap(s,o);continue}
   if(s.isCPU){o.cpuArmed-=dt;if(o.cpuArmed<=0){const crossed=(prev-o.cpuTarget)*(o.m-o.cpuTarget)<=0&&Math.abs(prev-o.m)<.5;if(crossed||o.cpuArmed<-4)this.tap(s,o)}}}
  if(this.phase==='playing'&&this.st[this.activeSeatIndex].done&&!this.st.every(o=>o.done)){this.turnWait+=dt;if(this.turnWait>1.1){this.turnWait=0;this.advanceTurn()}}
  if(this.phase==='playing'&&this.st.every(o=>o.done))this.finishGame()}
}
Arcade.register('powershot',PowerShotGame);
})();
