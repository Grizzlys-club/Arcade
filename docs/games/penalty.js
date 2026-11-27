(()=>{
const {Node,Sprite,Label,Shape,A,Gfx,Theme,rgba,white,label}=SK;
const Skin=id=>META.SKINS.find(k=>k.id===id);
class PenaltyGame extends MiniScene{
 static get layout(){return 'turns'}
 /* Echtes Penaltyschiessen: einer schiesst, der Gegner hält. Danach wird gewechselt. */
 keeperOf(i){const n=this.seats.length,me=this.seats[i];for(let k=1;k<n;k++){const j=(i+k)%n;if(this.seats[j].edge!==me.edge)return this.seats[j]}return this.seats[(i+1)%n]}
 setupGame(){this.duration=0;this.st=[];this.per=this.seats.length<=2?5:3;this.extra=0;this.shotsDone=0;this.wait=0;this.over=false;
  for(const s of this.seats){const kp=this.keeperOf(s.index),o={keeper:kp,goalie:null,goalieX:0,goalieDir:1,goalieHalf:20,flying:false,resolved:false,pos:{x:0,y:0},vel:{dx:0,dy:0},curve:0,resetTimer:0,cpuTimer:1,touchStart:null,touchTime:0,goalY:0,goalW:0,goalH:0,restY:0,ballR:9,shots:0,hint:null,reaction:0,goalieError:0,kTarget:null,idle:0,marks:[],res:[]};this.st.push(o);
   const w=s.w,h=s.h,scale=Math.min(1,w/300);
   const floor=new Sprite(PenaltyGame.floorTexture(w,h),w,h);floor.z=-10;s.field.add(floor);
   o.goalW=Math.min(w*.7,230);o.goalH=Math.max(48,o.goalW*.34);o.goalY=h/2-70-o.goalH;
   const g=new Sprite(Gfx.goal(o.goalW,o.goalH),o.goalW+16,o.goalH+12);g.x=0;g.y=o.goalY+o.goalH/2-2;g.z=2;s.field.add(g);o.goal=g;
   const crease=new Shape();const rad=o.goalW*.62;crease.path=c=>{c.beginPath();c.arc(0,0,rad,Math.PI,2*Math.PI,true)};crease.stroke=white(1,.18);crease.lw=2;crease.fill=rgba(.3,.6,1,.06);crease.x=0;crease.y=o.goalY;crease.z=1;s.field.add(crease);
   const gh=o.goalH*.9;const keeper=new BearNode(kp.skin,gh,false);keeper.x=0;keeper.y=o.goalY-6;keeper.z=5;keeper.startBob(2,.25);s.field.add(keeper);o.goalie=keeper;o.goalieHalf=gh*SKC.bearAspect*.42;
   const kl=label('IM TOR: '+kp.name.toUpperCase()+(kp.isCPU?' · CPU':''),14,kp.color);kl.rot=Math.PI;kl.y=o.goalY+o.goalH+34;kl.z=60;s.field.add(kl);
   if(!kp.isCPU){const kh=label('TORHÜTER: FINGER HIER ZIEHEN ↔',12,white(1,.75));kh.rot=Math.PI;kh.y=o.goalY+o.goalH+14;kh.z=60;s.field.add(kh);kh.run(A.forever(A.sequence([A.fadeTo(.35,.6),A.fadeTo(.9,.6)])))}
   o.restY=-h/2+70*Math.max(.8,scale);const spot=new Sprite(Gfx.dot(),8,8);spot.alpha=.5;spot.x=0;spot.y=o.restY-12;spot.z=1;s.field.add(spot);
   o.ballR=11*Math.max(.85,scale);
   const glow=new Sprite(Gfx.glow(),o.ballR*5,o.ballR*5);glow.color=s.color;glow.cbf=1;glow.blend='add';glow.alpha=.6;glow.z=6;s.field.add(glow);o.ballGlow=glow;
   const sh=new Sprite(Gfx.shadow(),o.ballR*2.4,o.ballR);sh.z=6;s.field.add(sh);o.shadow=sh;
   const b=new Sprite(Gfx.ball(14),o.ballR*2,o.ballR*2);b.z=8;s.field.add(b);o.ball=b;o.pos={x:0,y:o.restY};this.placeBall(o);
   const shooter=this.makeBear(s,44*Math.max(.85,scale),true);shooter.x=-o.ballR*3.2;shooter.y=o.restY-30;shooter.z=7;shooter.alpha=.95;s.field.add(shooter);
   if(!s.isCPU){const hint=new Node(),l=label('SCHÜTZE: WISCHEN ↑',16,s.color);l.y=o.restY+48;hint.add(l);hint.z=50;hint.run(A.forever(A.sequence([A.moveBy(0,8,.4),A.moveBy(0,-8,.4)])));s.field.add(hint);o.hint=hint}
   const sl=label('',12,white(1,.7));sl.ha='left';sl.x=-w/2+14;sl.y=h/2-34;sl.z=400;s.node.add(sl);o.shotLabel=sl;
   o.cpuTimer=1.1+Math.random()*.6;this.updMarks(s,o)}
  this.setActiveSeat(0)}
 updMarks(s,o){o.marks.forEach(m=>m.removeFromParent());o.marks=[];const tot=this.per+this.extra,gap=18,x0=-(tot-1)*gap/2;
  for(let i=0;i<tot;i++){const r=o.res[i],d=new Sprite(Gfx.circle(7,r===1?s.color:r===0?'rgba(255,60,60,.85)':'rgba(255,255,255,.12)',r==null?'rgba(255,255,255,.35)':null),14,14);d.x=x0+i*gap;d.y=o.restY-52;d.z=40;s.field.add(d);o.marks.push(d)}
  o.shotLabel.text='SCHUSS '+Math.min(tot,o.shots+1)+'/'+tot+(this.extra?' · VERLÄNGERUNG':'')}
 static floorTexture(w,h){return Gfx.texture('pen_floor'+Math.round(w)+'x'+Math.round(h),w,h,1,c=>{Gfx.gradientColors(c,rgba(.1,.16,.3,.9),rgba(.05,.08,.16,.9),w,h);c.strokeStyle=white(1,.07);c.lineWidth=1;c.beginPath();for(let y=0;y<h;y+=22){c.moveTo(0,y);c.lineTo(w,y)}c.stroke()})}
 placeBall(o){o.ball.x=o.pos.x;o.ball.y=o.pos.y;o.ballGlow.x=o.pos.x;o.ballGlow.y=o.pos.y;o.shadow.x=o.pos.x;o.shadow.y=o.pos.y-o.ballR*.9}
 get shooter(){return this.seats[this.activeSeatIndex]}
 seatFor(p){const sh=this.shooter;if(!sh)return null;const kp=this.st[sh.index].keeper;return sh.local(p).y>0&&kp!==sh?kp:sh}
 shoot(s,o,vel,curve){if(o.flying||o.resetTimer>0||this.phase!=='playing'||this.over)return;o.flying=true;o.resolved=false;o.vel=vel;o.curve=curve;o.shots++;o.idle=0;
  const d=this.difficulty;o.reaction=.05+Math.random()*.13+(d===0?.12:d===1?.05:0);o.goalieError=(Math.random()*2-1)*o.goalW*(d===0?.28:d===1?.18:.1);Sfx.play('kick');if(!s.isCPU)Haptic.tap('medium');
  if(o.hint){o.hint.run(A.sequence([A.fadeOut(.2),A.remove()]));o.hint=null}}
 began(seat,at){const sh=this.shooter,o=this.st[sh.index];if(seat!==sh){o.kTarget=sh.local(seat.toScene(at)).x;return}o.touchStart=at;o.touchTime=this.elapsed}
 moved(seat,at){const sh=this.shooter,o=this.st[sh.index];if(seat!==sh){o.kTarget=sh.local(seat.toScene(at)).x;return}if(!o.touchStart)return;if(Math.hypot(at.x-o.touchStart.x,at.y-o.touchStart.y)>110)this.release(seat,at)}
 ended(seat,at){if(seat===this.shooter)this.release(seat,at)}
 release(seat,at){const o=this.st[seat.index];if(!o.touchStart)return;const start=o.touchStart;o.touchStart=null;const dx=at.x-start.x,dy=at.y-start.y;if(dy<18)return;
  const t=Math.max(.04,this.elapsed-o.touchTime),len=Math.hypot(dx,dy),speed=Math.max(seat.h*1.5,Math.min(seat.h*2.6,len/t*.9)),dir={dx:dx/len,dy:dy/len};
  this.shoot(seat,o,{dx:dir.dx*speed,dy:dir.dy*speed},0)}
 gameUpdate(dt){if(this.over)return;const s=this.shooter,o=this.st[s.index];this.updateGoalie(s,o,dt);
  if(o.flying){o.vel.dx+=o.curve*dt;o.pos.x+=o.vel.dx*dt;o.pos.y+=o.vel.dy*dt;const total=o.goalY-o.restY,prog=Math.max(0,Math.min(1.2,(o.pos.y-o.restY)/total));
   o.ball.setScale(1-.38*prog);o.ballGlow.setScale(1-.38*prog);o.ball.rot+=dt*12;o.shadow.x=o.pos.x;o.shadow.y=o.pos.y-o.ballR*(.9+prog*1.6);o.ball.x=o.pos.x;o.ball.y=o.pos.y;o.ballGlow.x=o.pos.x;o.ballGlow.y=o.pos.y;
   if(!o.resolved&&(o.pos.y>=o.goalY||Math.abs(o.pos.x)>s.w/2+20))this.resolve(s,o);
   if(o.resolved&&o.vel.dy>0&&o.pos.y>o.goalY+o.goalH*.75)o.vel={dx:o.vel.dx*.2,dy:0}}
  if(o.resetTimer>0){o.resetTimer-=dt;if(o.resetTimer<=0){o.flying=false;o.pos={x:0,y:o.restY};o.ball.setScale(1);o.ballGlow.setScale(1);o.ball.alpha=1;this.placeBall(o);this.nextShot()}return}
  if(!o.flying){o.idle+=dt;if(s.isCPU){o.cpuTimer-=dt;if(o.cpuTimer<=0)this.cpuShoot(s,o)}else if(o.idle>8){s.floatText('ZU LANGSAM!',{x:0,y:0},white(1,.9),18);this.cpuShoot(s,o,.35)}}}
 updateGoalie(s,o,dt){const kp=o.keeper,limit=o.goalW/2-o.goalieHalf*.55;
  if(!kp.isCPU){if(o.kTarget!=null){const t=Math.max(-limit,Math.min(limit,o.kTarget)),mx=o.goalW*2.4*dt,d=t-o.goalieX;o.goalieX+=Math.max(-mx,Math.min(mx,d));if(Math.abs(d)>2)o.goalieDir=d>0?1:-1}}
  else{const dk=this.difficulty===0?.75:this.difficulty===1?1:1.25;
   if(o.flying&&!o.resolved){o.reaction-=dt;if(o.reaction<=0){const tLeft=Math.max(.01,(o.goalY-o.pos.y)/Math.max(1,o.vel.dy)),px=o.pos.x+o.vel.dx*tLeft+o.goalieError,target=Math.max(-limit,Math.min(limit,px)),mxs=o.goalW*1.5*dk,d=target-o.goalieX;o.goalieX+=Math.max(-mxs*dt,Math.min(mxs*dt,d))}}
   else{const patrol=o.goalW*.45*dk;o.goalieX+=o.goalieDir*patrol*dt;if(o.goalieX>limit){o.goalieX=limit;o.goalieDir=-1}if(o.goalieX<-limit){o.goalieX=-limit;o.goalieDir=1}}}
  o.goalie.x=o.goalieX;o.goalie.setFacing(o.goalieDir>0)}
 resolve(s,o){o.resolved=true;const kp=o.keeper,inGoal=Math.abs(o.pos.x)<o.goalW/2-o.ballR*.5&&o.pos.y>=o.goalY-2,saved=Math.abs(o.pos.x-o.goalieX)<o.goalieHalf+o.ballR*.6,center={x:o.pos.x,y:o.goalY+10};
  if(inGoal&&!saved){o.res.push(1);this.addScore(s,1);this.addStat('goals',1,s);s.banner('TOR!',s.color,50,.6);s.burst(center,s.color,18,150);s.burst(center,'#fff',8,90);
   const shake=A.sequence([A.moveBy(0,5,.05),A.moveBy(0,-5,.08)]);o.goal.run(A.repeat(shake,3));Sfx.play('goal');if(!s.isCPU)Haptic.good();o.vel={dx:o.vel.dx*.3,dy:o.vel.dy*.35}}
  else if(saved&&inGoal){o.res.push(0);const t=label('GEHALTEN! '+kp.name.toUpperCase(),20,kp.color);t.rot=Math.PI;t.x=o.goalieX;t.y=o.goalY-34;t.z=300;s.field.add(t);t.setScale(.3);t.run(A.sequence([A.scaleTo(1.2,.1),A.scaleTo(1,.1),A.wait(.6),A.fadeOut(.3),A.remove()]));
   o.goalie.squash();s.shake(7);s.burst(center,kp.color,14,120);o.vel={dx:(Math.random()*2-1)*s.w*.8,dy:-Math.abs(o.vel.dy)*.35};Sfx.play('save');if(!kp.isCPU)Haptic.good()}
  else{o.res.push(0);const hitPost=Math.abs(Math.abs(o.pos.x)-o.goalW/2)<o.ballR*1.6&&o.pos.y>=o.goalY-4;s.floatText(hitPost?'PFOSTEN!':'DANEBEN',{x:Math.max(-s.w/2+50,Math.min(s.w/2-50,o.pos.x)),y:o.goalY-26},white(1,.8),18);
   if(hitPost){o.vel={dx:-o.vel.dx*.6,dy:-Math.abs(o.vel.dy)*.4};Sfx.play('hit')}else Sfx.play('miss')}
  this.updMarks(s,o);o.ball.run(A.sequence([A.wait(.45),A.fadeOut(.2)]));o.resetTimer=1.1}
 nextShot(){const n=this.seats.length,tot=this.per+this.extra;
  if(this.st.every(o=>o.shots>=tot)){const sc=this.seats.map(x=>x.score),best=Math.max(...sc),lead=sc.filter(v=>v===best).length;
   if(lead>1&&this.extra<3){this.extra++;this.bannerAll('VERLÄNGERUNG!','#ff8a00',36,1);Sfx.play('whistle');this.seats.forEach(x=>this.updMarks(x,this.st[x.index]))}
   else{this.over=true;this.finishGame();return}}
  for(let k=1;k<=n;k++){const j=(this.activeSeatIndex+k)%n;if(this.st[j].shots<this.per+this.extra){const q=this.st[j];q.idle=0;q.kTarget=null;q.cpuTimer=1+Math.random()*.6;this.setActiveSeat(j);return}}}
 cpuShoot(s,o,weak){const side=o.goalieX>0?-1:1,acc=weak!=null?weak:s.skill;let tx=side*(o.goalW/2-o.ballR*1.5)*(.5+.45*acc);tx+=(Math.random()*2-1)*o.goalW*.42*(1.1-acc);
  const dx=tx-o.pos.x,dy=o.goalY+4-o.pos.y,len=Math.hypot(dx,dy),speed=s.h*(1.6+1*acc);this.shoot(s,o,{dx:dx/len*speed,dy:dy/len*speed},0)}
}
Arcade.register('penalty',PenaltyGame);
})();
