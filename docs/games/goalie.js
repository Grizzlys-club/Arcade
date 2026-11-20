(()=>{
const {Node,Sprite,A,Gfx,Theme,rgba,white,label}=SK;
const Skin=id=>META.SKINS.find(k=>k.id===id);
const alpha=(c,a)=>c.replace(/[\d.]+\)$/,a+')');
const rr=(a,b)=>a+Math.random()*(b-a);
class GoalieGame extends MiniScene{
 setupGame(){this.duration=75;this.hadHumans=this.seats.some(s=>!s.isCPU);this.ff=false;this.st=[];
  for(const s of this.seats){const o={rand:this.newRand(),keeperX:0,targetX:0,shots:[],spawnTimer:1,shotCount:0,lives:3,lifeNodes:[]};this.st.push(o);const w=s.w,h=s.h,scale=Math.min(1,w/300);
   const floor=new Sprite(Gfx.texture('goalie_floor'+Math.floor(w)+'x'+Math.floor(h),w,h,1,c=>{Gfx.gradientColors(c,rgba(.05,.12,.12,.9),rgba(.08,.2,.18,.9),w,h);c.strokeStyle='rgba(255,255,255,.06)';c.lineWidth=1;c.beginPath();for(let x=0;x<w;x+=24){c.moveTo(x,0);c.lineTo(x,h)}c.stroke()}),w,h);floor.z=-10;s.field.add(floor);
   o.goalW=Math.min(w*.82,240);o.goalH=Math.max(40,o.goalW*.26);const g=new Sprite(Gfx.goal(o.goalW,o.goalH),o.goalW+16,o.goalH+12);g.rot=Math.PI;g.y=-h/2+o.goalH/2+4;g.z=2;s.field.add(g);o.goal=g;o.lineY=-h/2+o.goalH+6;
   const cr=Math.floor(o.goalW*.6),crease=new Sprite(Gfx.texture('goalie_crease'+cr+s.color,cr*2+6,cr+6,2,c=>{c.beginPath();c.arc(cr+3,cr+3,cr,Math.PI,2*Math.PI);c.closePath();c.fillStyle=alpha(s.color,.06);c.fill();c.strokeStyle=alpha(s.color,.35);c.lineWidth=2;c.stroke()}),cr*2+6,cr+6);crease.ay=0;crease.y=o.lineY-3;crease.z=1;s.field.add(crease);
   o.keeperH=50*Math.max(.8,scale);const k=this.makeBear(s,o.keeperH,false);k.y=o.lineY-o.keeperH*.35;k.z=6;s.field.add(k);o.keeper=k;o.keeperHalf=o.keeperH*SKC.bearAspect*.5;
   const glove=new Sprite(Gfx.glow(),o.keeperHalf*3,o.keeperH);glove.color=s.color;glove.cbf=1;glove.blend='add';glove.alpha=.35;glove.y=o.keeperH*.5;glove.z=-1;k.add(glove);
   const sh=new BearNode(Skin(s.skin.id==='fire'?'blue':'fire'),38*Math.max(.85,scale),false);sh.y=h/2-40-38*Math.max(.85,scale);sh.z=5;sh.alpha=.9;s.field.add(sh);o.shooter=sh;o.ballR=9*Math.max(.85,scale);
   for(let i=0;i<3;i++){const l=new Sprite(Gfx.circle(8,s.color,'#fff'),13,13);l.x=-w/2+20+i*17;l.y=h/2-36;l.z=400;s.node.add(l);o.lifeNodes.push(l)}
   if(!s.isCPU){const hint=new Node(),l=label('← ZIEHEN →',17,s.color);l.y=o.lineY+34;hint.add(l);hint.z=50;s.field.add(hint);o.hint=hint}
   o.nextShotX=o.rand.range(-w*.3,w*.3)}}
 began(seat,at){const o=this.st[seat.index];o.targetX=at.x;if(o.hint){o.hint.run(A.sequence([A.fadeOut(.3),A.remove()]));o.hint=null}}
 moved(seat,at){this.st[seat.index].targetX=at.x}
 gameUpdate(dtIn){if(this.hadHumans&&!this.humansAlive&&!this.ff){this.ff=true;this.bannerAll('⏩','#fff',40,.6)}const dt=this.ff?dtIn*3:dtIn;
  for(const s of this.seats){const o=this.st[s.index];
   if(!s.alive){for(const sh of o.shots){if(!sh.done){sh.done=true;sh.node.removeFromParent();sh.glow.removeFromParent()}}o.shots=[];continue}
   o.spawnTimer-=dt;if(o.spawnTimer<=0){this.spawn(s,o);o.spawnTimer=Math.max(.5,1.55-this.elapsed*.017)*o.rand.range(.85,1.15)}
   o.shooter.x+=(o.nextShotX-o.shooter.x)*Math.min(1,dt*6);
   if(s.isCPU)this.cpuTarget(s,o);const limit=s.w/2-o.keeperHalf*.7,tgt=Math.max(-limit,Math.min(limit,o.targetX)),d=tgt-o.keeperX;
   if(s.isCPU){const ms=s.w*(.9+s.skill*1.6);o.keeperX+=Math.max(-ms*dt,Math.min(ms*dt,d))}else o.keeperX+=d*Math.min(1,dt*24);
   o.keeper.x=o.keeperX;if(Math.abs(d)>2)o.keeper.setFacing(d>0);
   for(const sh of o.shots){if(sh.done)continue;sh.vx+=sh.curve*dt;sh.x+=sh.vx*dt;sh.y+=sh.vy*dt;
    if(sh.x<-s.w/2+o.ballR){sh.x=-s.w/2+o.ballR;sh.vx=Math.abs(sh.vx);sh.curve=0}if(sh.x>s.w/2-o.ballR){sh.x=s.w/2-o.ballR;sh.vx=-Math.abs(sh.vx);sh.curve=0}
    sh.node.x=sh.x;sh.node.y=sh.y;sh.glow.x=sh.x;sh.glow.y=sh.y;sh.node.rot+=dt*10;const prog=(s.h/2-sh.y)/s.h;sh.node.setScale(.75+.4*Math.max(0,Math.min(1,prog)));
    // Extra: Schweif
    if(Math.random()<.5){const q=new Sprite(Gfx.dot(),o.ballR*1.2,o.ballR*1.2);q.color=sh.curved?rgba(1,.4,.9):rgba(1,.85,.4);q.cbf=1;q.blend='add';q.alpha=.5;q.x=sh.x;q.y=sh.y;q.z=6;s.field.add(q);q.run(A.sequence([A.group([A.fadeOut(.25),A.scaleTo(.2,.25)]),A.remove()]))}
    const saveTop=o.lineY+o.keeperH*.55;
    if(sh.y<=saveTop&&sh.y>o.lineY-o.keeperH*.4&&Math.abs(sh.x-o.keeperX)<o.keeperHalf+o.ballR){this.save(s,o,sh);continue}
    if(sh.y<=o.lineY-6){if(Math.abs(sh.x)<o.goalW/2-4)this.conceded(s,o,sh);else{sh.done=true;sh.node.run(A.sequence([A.fadeOut(.2),A.remove()]));sh.glow.removeFromParent();s.floatText('VORBEI',{x:sh.x*.7,y:o.lineY+20},white(1,.6),14)}}}
   o.shots=o.shots.filter(x=>!x.done)}
  this.checkEnd()}
 spawn(s,o){const r=o.rand;o.shotCount++;const start={x:o.nextShotX,y:o.shooter.y+14},tx=r.range(-o.goalW*.46,o.goalW*.46),curved=r.chance(Math.min(.6,.15+this.elapsed*.008)),curve=curved?r.range(-1,1)*s.w*1.6:0,speed=s.h*(.95+Math.min(70,this.elapsed)*.03)*r.range(.9,1.2);
  const dy=o.lineY-start.y,T=Math.abs(dy)/speed,vx=(tx-start.x-.5*curve*T*T)/T;
  const node=new Sprite(Gfx.ball(14),o.ballR*2,o.ballR*2);node.x=start.x;node.y=start.y;node.z=8;
  const glow=new Sprite(Gfx.glow(),o.ballR*4.5,o.ballR*4.5);glow.color=curved?rgba(1,.4,.9):rgba(1,.85,.4);glow.cbf=1;glow.blend='add';glow.alpha=.7;glow.x=start.x;glow.y=start.y;glow.z=7;s.field.add(glow);s.field.add(node);
  o.shots.push({node,glow,x:start.x,y:start.y,vx,vy:-speed,curve,curved,done:false,cpuNoise:(Math.random()*2-1)*o.goalW*.5*(1.05-s.skill)});
  o.shooter.squash();o.nextShotX=r.range(-s.w*.32,s.w*.32);if(s===this.aliveSeats[0])Sfx.play('kick')}
 cpuTarget(s,o){let shot=null;for(const x of o.shots){if(!x.done&&(!shot||x.y<shot.y))shot=x}if(!shot){o.targetX=o.keeperX*.95;return}
  const win=s.h*(.55+s.skill*.4);if(shot.y-o.lineY>win)return;const tl=Math.max(.01,(shot.y-o.lineY)/Math.max(1,-shot.vy)),px=shot.x+shot.vx*tl+.5*shot.curve*tl*tl;o.targetX=px+shot.cpuNoise}
 save(s,o,sh){sh.done=true;this.addScore(s,1);this.addStat('balls',1,s);o.keeper.squash();s.burst({x:sh.x,y:sh.y},s.color,14,120);s.floatText('+1',{x:sh.x,y:sh.y+20},s.color,20);Sfx.play('save');if(!s.isCPU)Haptic.tap('medium');sh.glow.removeFromParent();
  const ring=new Sprite(Gfx.circle(14,'rgba(0,0,0,0)',s.color),28,28);ring.blend='add';ring.x=sh.x;ring.y=sh.y;ring.z=9;s.field.add(ring);ring.run(A.sequence([A.group([A.scaleTo(3,.25),A.fadeOut(.25)]),A.remove()]));
  sh.node.run(A.sequence([A.group([A.moveBy((Math.random()*2-1)*s.w*.6,s.h*.5,.45),A.fadeOut(.45),A.scaleTo(.4,.45)]),A.remove()]))}
 conceded(s,o,sh){sh.done=true;sh.glow.removeFromParent();sh.node.run(A.sequence([A.moveBy(0,-10,.1),A.fadeOut(.2),A.remove()]));o.lives--;
  if(o.lives>=0&&o.lives<o.lifeNodes.length)o.lifeNodes[o.lives].run(A.group([A.scaleTo(1.8,.2),A.fadeTo(.15,.2)]));
  s.flash('#f00',.35);s.shake(7);s.floatText('TOR!',{x:sh.x,y:o.lineY+24},'#f00',22);s.burst({x:sh.x,y:o.lineY},'#f00',12,100);o.goal.run(A.sequence([A.moveBy(0,-4,.05),A.moveBy(0,4,.08)]));Sfx.play('wrong');if(!s.isCPU)Haptic.bad();
  if(o.lives<=0){s.knockOut('RAUS');Sfx.play('lose')}}
 checkEnd(){if(this.phase!=='playing')return;const alive=this.aliveSeats;if(!alive.length){this.finishGame();return}
  if(alive.length===1&&this.n>1){const a=alive[0],others=Math.max(...this.seats.filter(s=>s!==a).map(s=>s.score));if(a.score>others)this.finishGame()}}
}
Arcade.register('goalie',GoalieGame);
})();
