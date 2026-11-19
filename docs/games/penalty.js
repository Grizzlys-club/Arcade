(()=>{
const {Node,Sprite,Label,Shape,A,Gfx,Theme,rgba,white,label}=SK;
const Skin=id=>META.SKINS.find(k=>k.id===id);
class PenaltyGame extends MiniScene{
 setupGame(){this.duration=40;this.st=[];
  for(const s of this.seats){const o={goalie:null,goalieX:0,goalieDir:1,goalieHalf:20,flying:false,resolved:false,pos:{x:0,y:0},vel:{dx:0,dy:0},curve:0,resetTimer:0,cpuTimer:1,touchStart:null,touchTime:0,goalY:0,goalW:0,goalH:0,restY:0,ballR:9,shots:0,hint:null,reaction:0,goalieError:0};this.st.push(o);
   const w=s.w,h=s.h,scale=Math.min(1,w/300);
   const floor=new Sprite(PenaltyGame.floorTexture(w,h),w,h);floor.z=-10;s.field.add(floor);
   o.goalW=Math.min(w*.74,220);o.goalH=Math.max(44,o.goalW*.34);o.goalY=h/2-40-o.goalH;
   const g=new Sprite(Gfx.goal(o.goalW,o.goalH),o.goalW+16,o.goalH+12);g.x=0;g.y=o.goalY+o.goalH/2-2;g.z=2;s.field.add(g);o.goal=g;
   const crease=new Shape();const rad=o.goalW*.62;crease.path=c=>{c.beginPath();c.arc(0,0,rad,Math.PI,2*Math.PI,true)};crease.stroke=white(1,.18);crease.lw=2;crease.fill=rgba(.3,.6,1,.06);crease.x=0;crease.y=o.goalY;crease.z=1;s.field.add(crease);
   const gh=o.goalH*.82;const keeper=new BearNode(Skin(s.skin.id==='classic'?'ice':'classic'),gh,false);keeper.x=0;keeper.y=o.goalY-6;keeper.z=5;keeper.startBob(2,.25);s.field.add(keeper);o.goalie=keeper;o.goalieHalf=gh*SKC.bearAspect*.42;
   o.restY=-h/2+52*Math.max(.8,scale);const spot=new Sprite(Gfx.dot(),8,8);spot.alpha=.5;spot.x=0;spot.y=o.restY-12;spot.z=1;s.field.add(spot);
   o.ballR=10*Math.max(.85,scale);
   const glow=new Sprite(Gfx.glow(),o.ballR*5,o.ballR*5);glow.color=s.color;glow.cbf=1;glow.blend='add';glow.alpha=.6;glow.z=6;s.field.add(glow);o.ballGlow=glow;
   const sh=new Sprite(Gfx.shadow(),o.ballR*2.4,o.ballR);sh.z=6;s.field.add(sh);o.shadow=sh;
   const b=new Sprite(Gfx.ball(14),o.ballR*2,o.ballR*2);b.z=8;s.field.add(b);o.ball=b;o.pos={x:0,y:o.restY};this.placeBall(o);
   const shooter=this.makeBear(s,38*Math.max(.85,scale),true);shooter.x=-o.ballR*3.2;shooter.y=o.restY-26;shooter.z=7;shooter.alpha=.95;s.field.add(shooter);
   if(!s.isCPU){const hint=new Node(),l=label('WISCHEN ↑',18,s.color);l.y=o.restY+46;hint.add(l);hint.z=50;hint.run(A.forever(A.sequence([A.moveBy(0,8,.4),A.moveBy(0,-8,.4)])));s.field.add(hint);o.hint=hint}
   o.cpuTimer=1+Math.random()*.6}}
 static floorTexture(w,h){return Gfx.texture('pen_floor'+Math.round(w)+'x'+Math.round(h),w,h,1,c=>{Gfx.gradientColors(c,rgba(.1,.16,.3,.9),rgba(.05,.08,.16,.9),w,h);c.strokeStyle=white(1,.07);c.lineWidth=1;c.beginPath();for(let y=0;y<h;y+=22){c.moveTo(0,y);c.lineTo(w,y)}c.stroke()})}
 placeBall(o){o.ball.x=o.pos.x;o.ball.y=o.pos.y;o.ballGlow.x=o.pos.x;o.ballGlow.y=o.pos.y;o.shadow.x=o.pos.x;o.shadow.y=o.pos.y-o.ballR*.9}
 shoot(s,o,vel,curve){if(o.flying||o.resetTimer>0||this.phase!=='playing')return;o.flying=true;o.resolved=false;o.vel=vel;o.curve=curve;o.shots++;
  o.reaction=.05+Math.random()*.13+(this.difficulty===0?.12:this.difficulty===1?.05:0);
  o.goalieError=(Math.random()*2-1)*o.goalW*(this.difficulty===0?.28:this.difficulty===1?.18:.1);Sfx.play('kick');if(!s.isCPU)Haptic.tap('medium');
  if(o.hint){o.hint.run(A.sequence([A.fadeOut(.2),A.remove()]));o.hint=null}}
 began(seat,at){const o=this.st[seat.index];o.touchStart=at;o.touchTime=this.elapsed}
 moved(seat,at){const o=this.st[seat.index];if(!o.touchStart)return;if(Math.hypot(at.x-o.touchStart.x,at.y-o.touchStart.y)>110)this.release(seat,at)}
 ended(seat,at){this.release(seat,at)}
 release(seat,at){const o=this.st[seat.index];if(!o.touchStart)return;const start=o.touchStart;o.touchStart=null;const dx=at.x-start.x,dy=at.y-start.y;if(dy<18)return;
  const t=Math.max(.04,this.elapsed-o.touchTime),len=Math.hypot(dx,dy),speed=Math.max(seat.h*1.6,Math.min(seat.h*3.6,len/t*.9)),dir={dx:dx/len,dy:dy/len};
  this.shoot(seat,o,{dx:dir.dx*speed,dy:dir.dy*speed},0)}
 gameUpdate(dt){for(const s of this.seats){const o=this.st[s.index];this.updateGoalie(s,o,dt);
  if(o.flying){o.vel.dx+=o.curve*dt;o.pos.x+=o.vel.dx*dt;o.pos.y+=o.vel.dy*dt;const total=o.goalY-o.restY,prog=Math.max(0,Math.min(1.2,(o.pos.y-o.restY)/total));
   o.ball.setScale(1-.38*prog);o.ballGlow.setScale(1-.38*prog);o.ball.rot+=dt*12;o.shadow.x=o.pos.x;o.shadow.y=o.pos.y-o.ballR*(.9+prog*1.6);o.ball.x=o.pos.x;o.ball.y=o.pos.y;o.ballGlow.x=o.pos.x;o.ballGlow.y=o.pos.y;
   if(!o.resolved&&(o.pos.y>=o.goalY||Math.abs(o.pos.x)>s.w/2+20))this.resolve(s,o);
   if(o.resolved&&o.vel.dy>0&&o.pos.y>o.goalY+o.goalH*.75)o.vel={dx:o.vel.dx*.2,dy:0}}
  if(o.resetTimer>0){o.resetTimer-=dt;if(o.resetTimer<=0){o.flying=false;o.pos={x:0,y:o.restY};o.ball.setScale(1);o.ballGlow.setScale(1);o.ball.alpha=0;o.ball.run(A.fadeIn(.15));this.placeBall(o)}}
  if(s.isCPU&&!o.flying&&o.resetTimer<=0){o.cpuTimer-=dt;if(o.cpuTimer<=0){this.cpuShoot(s,o);o.cpuTimer=1.25+Math.random()*.6-s.skill*.25}}}}
 updateGoalie(s,o,dt){const limit=o.goalW/2-o.goalieHalf*.6,diffK=this.difficulty===0?.75:this.difficulty===1?1:1.25,speedUp=1+this.elapsed*.025;
  if(o.flying&&!o.resolved){o.reaction-=dt;if(o.reaction<=0){const tLeft=Math.max(.01,(o.goalY-o.pos.y)/Math.max(1,o.vel.dy)),px=o.pos.x+o.vel.dx*tLeft+.5*o.curve*tLeft*tLeft+o.goalieError,target=Math.max(-limit,Math.min(limit,px)),maxSpeed=o.goalW*1.5*diffK*speedUp,d=target-o.goalieX;o.goalieX+=Math.max(-maxSpeed*dt,Math.min(maxSpeed*dt,d))}}
  else{const patrol=o.goalW*.45*diffK*speedUp;o.goalieX+=o.goalieDir*patrol*dt;if(o.goalieX>limit){o.goalieX=limit;o.goalieDir=-1}if(o.goalieX<-limit){o.goalieX=-limit;o.goalieDir=1}}
  o.goalie.x=o.goalieX;o.goalie.setFacing(o.goalieDir>0)}
 resolve(s,o){o.resolved=true;const inGoal=Math.abs(o.pos.x)<o.goalW/2-o.ballR*.5&&o.pos.y>=o.goalY-2,saved=Math.abs(o.pos.x-o.goalieX)<o.goalieHalf+o.ballR*.6,center={x:o.pos.x,y:o.goalY+10};
  if(inGoal&&!saved){this.addScore(s,1);this.addStat('goals',1,s);s.banner('TOR!',s.color,46,.5);s.burst(center,s.color,16,140);s.burst(center,'#fff',8,90);
   const shake=A.sequence([A.moveBy(0,5,.05),A.moveBy(0,-5,.08)]);o.goal.run(A.repeat(shake,3));Sfx.play('goal');if(!s.isCPU)Haptic.good();o.vel={dx:o.vel.dx*.3,dy:o.vel.dy*.35}}
  else if(saved&&inGoal){s.floatText('GEHALTEN',{x:o.goalieX,y:o.goalY-30},white(1,.9),18);o.goalie.squash();o.vel={dx:(Math.random()*2-1)*s.w*.8,dy:-Math.abs(o.vel.dy)*.35};Sfx.play('save');if(!s.isCPU)Haptic.bad()}
  else{const hitPost=Math.abs(Math.abs(o.pos.x)-o.goalW/2)<o.ballR*1.6&&o.pos.y>=o.goalY-4;s.floatText(hitPost?'PFOSTEN!':'DANEBEN',{x:Math.max(-s.w/2+50,Math.min(s.w/2-50,o.pos.x)),y:o.goalY-26},white(1,.8),17);
   if(hitPost){o.vel={dx:-o.vel.dx*.6,dy:-Math.abs(o.vel.dy)*.4};Sfx.play('hit')}else Sfx.play('miss')}
  o.ball.run(A.sequence([A.wait(.35),A.fadeOut(.2)]));o.resetTimer=.75}
 cpuShoot(s,o){const side=o.goalieX>0?-1:1,acc=s.skill;let tx=side*(o.goalW/2-o.ballR*1.5)*(.5+.45*acc);tx+=(Math.random()*2-1)*o.goalW*.42*(1.1-acc);
  const dx=tx-o.pos.x,dy=o.goalY+4-o.pos.y,len=Math.hypot(dx,dy),speed=s.h*(2+1.3*acc);this.shoot(s,o,{dx:dx/len*speed,dy:dy/len*speed},0)}
}
Arcade.register('penalty',PenaltyGame);
})();
