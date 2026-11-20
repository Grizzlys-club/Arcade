(()=>{
const {Node,Sprite,A,Gfx,Theme,rgba,white,label}=SK;
const alpha=(c,a)=>c.replace(/[\d.]+\)$/,a+')');
const coneTex=()=>Gfx.texture('dash_cone',40,44,2,c=>{c.fillStyle='#ff8a00';c.beginPath();c.moveTo(20,2);c.lineTo(34,38);c.lineTo(6,38);c.closePath();c.fill();c.fillStyle='#fff';c.fillRect(12,18,16,6);c.fillStyle='rgb(38,38,38)';c.fillRect(2,37,36,6)});
const hurdleTex=()=>Gfx.texture('dash_hurdle',80,26,2,c=>{c.fillStyle='rgb(230,230,230)';c.fillRect(2,4,76,12);c.fillStyle='rgb(230,38,38)';for(let x=2;x<78;x+=16)c.fillRect(x,4,8,12);c.fillStyle='rgb(77,77,77)';c.fillRect(6,14,4,10);c.fillRect(70,14,4,10)});
class DashGame extends MiniScene{
 setupGame(){this.duration=50;this.runSpeed=220;this.st=this.seats.map(()=>({rand:this.newRand(),lane:1,lives:3,dist:0,balls:0,nextRow:260,objs:[],invuln:0,laneX:[],stripes:[],hearts:[],cpuT:0}));
  for(const s of this.seats){const g=this.st[s.index],lw=Math.min(s.w*.29,96);g.laneX=[-lw,0,lw];
   const track=new Sprite(Gfx.pill(lw*3+12,s.h+40,rgba(.12,.1,.2,.95),alpha(s.color,.7),10),lw*3+12,s.h+40);track.z=-6;s.field.add(track);
   const perLane=Math.floor((s.h+80)/40)+1;g.stripeSpan=perLane*40;
   for(const lx of[-lw/2,lw/2])for(let k=0;k<perLane;k++){const y=-s.h/2-20+k*40,st2=new Sprite(null,3,18,white(1,.25));st2.x=lx;st2.y=y;st2.z=-5;s.field.add(st2);g.stripes.push(st2)}
   g.bearY=-s.h/2+34;const bh=Math.min(52,s.w*.24),bear=this.makeBear(s,bh);bear.x=0;bear.y=g.bearY;bear.z=20;s.field.add(bear);bear.startRun(.11);g.bear=bear;
   for(let i=0;i<3;i++){const h=label('❤️',13);h.x=-s.w/2+18+i*17;h.y=s.h/2-36;h.z=30;s.node.add(h);g.hearts.push(h)}
   const hint=label('◀ TIPPEN ▶',Math.min(20,s.w*.1),'#fff');hint.y=-s.h/2+100;hint.z=40;s.field.add(hint);hint.run(A.sequence([A.wait(4.6),A.fadeOut(.4),A.remove()]))}}
 spawnRow(s){const g=this.st[s.index],r=g.rand,blocked=r.chance(.35)?2:1;let lanes=r.shuffled([0,1,2]);const blockLanes=lanes.slice(0,blocked);lanes=lanes.slice(blocked);const y=s.h/2+30;
  for(const l of blockLanes){const roll=r.double(),kind=roll<.45?'cone':(roll<.8?'hurdle':'goal'),lw=g.laneX[2];let node;
   if(kind==='cone')node=new Sprite(coneTex(),Math.min(34,lw*.6),Math.min(37,lw*.65));else if(kind==='hurdle')node=new Sprite(hurdleTex(),lw*.9,lw*.3);else node=new Sprite(Gfx.goal(60,26),lw*.9,lw*.42);
   node.x=g.laneX[l];node.y=y;node.z=10;s.field.add(node);g.objs.push({node,kind,lane:l,y,alive:true})}
  if(r.chance(.65)&&lanes.length){const l=lanes[0],b=new Sprite(Gfx.ball(12),20,20);b.x=g.laneX[l];b.y=y;b.z=9;const glow=new Sprite(Gfx.glow(),44,44);glow.blend='add';glow.alpha=.35;glow.z=-1;b.add(glow);s.field.add(b);g.objs.push({node:b,kind:'ball',lane:l,y,alive:true})}
  g.nextRow=g.dist+Math.max(150,240-g.dist*.012)*r.range(.9,1.15)}
 setLane(s,l){const g=this.st[s.index],nl=Math.max(0,Math.min(2,l));if(nl===g.lane)return;const right=nl>g.lane;g.lane=nl;g.bear.removeAction('lane');g.bear.run(A.moveToX(g.laneX[nl],.1),'lane');g.bear.setFacing(right);Sfx.play('tap')}
 updateScore(s){const g=this.st[s.index],v=Math.floor(g.dist/10)+g.balls*5;if(v!==s.score){s.score=v;if(s.scoreLabel)s.scoreLabel.text=''+v}}
 gameUpdate(d){this.runSpeed=220+this.elapsed*6.5;
  for(const s of this.seats){const g=this.st[s.index],move=this.runSpeed*d,sm=s.alive?move:move*.2;
   for(const stp of g.stripes){stp.y-=sm;if(stp.y<-s.h/2-20)stp.y+=g.stripeSpan}
   if(!s.alive)continue;g.dist+=move;if(g.dist>=g.nextRow)this.spawnRow(s);
   if(g.invuln>0){g.invuln-=d;g.bear.alpha=(Math.floor(g.invuln*12)%2===0)?.35:1;if(g.invuln<=0)g.bear.alpha=1}
   for(const o of g.objs){if(!o.alive)continue;o.y-=move;o.node.y=o.y;
    if(o.lane===g.lane&&Math.abs(o.y-(g.bearY+14))<22){
     if(o.kind==='ball'){o.alive=false;g.balls++;this.addStat('balls',1,s);s.floatText('+5',{x:o.node.x,y:o.y+10},'#ff0',18);o.node.run(A.sequence([A.group([A.scaleTo(1.8,.15),A.fadeOut(.15)]),A.remove()]));Sfx.play('coin')}
     else if(g.invuln<=0)this.hit(s,o)}
    if(o.y<-s.h/2-40){o.alive=false;o.node.removeFromParent()}}
   g.objs=g.objs.filter(o=>o.alive);this.updateScore(s);if(s.isCPU&&s.alive)this.cpu(s,d)}
  if(this.seats.every(s=>!s.alive))this.finishGame()}
 hit(s,o){const g=this.st[s.index];g.lives--;g.invuln=1.3;o.node.run(A.group([A.rotateBy(2,.3),A.moveBy(0,30,.3),A.fadeOut(.3)]));o.alive=false;s.shake(7);s.flash('#f00',.3);g.bear.squash();Sfx.play('stomp');if(!s.isCPU)Haptic.bad();
  if(g.lives>=0&&g.lives<g.hearts.length)g.hearts[g.lives].run(A.sequence([A.scaleTo(1.6,.1),A.fadeTo(.15,.2)]));
  if(g.lives<=0){g.bear.stopRun();g.bear.alpha=1;g.bear.run(A.rotateTo(Math.PI/2,.3));this.updateScore(s);s.knockOut('RAUS');Sfx.play('lose')}}
 blocked(g,lane,within){return g.objs.some(o=>o.alive&&o.kind!=='ball'&&o.lane===lane&&o.y>g.bearY-10&&o.y-g.bearY<within)}
 cpu(s,dt){const g=this.st[s.index];g.cpuT-=dt;if(g.cpuT>0)return;g.cpuT=.09+(1-s.skill)*.2;const look=110+s.skill*120+this.runSpeed*.15;
  if(this.blocked(g,g.lane,look)){if(Math.random()<(1-s.skill)*.25)return;const opts=[g.lane-1,g.lane+1].filter(l=>l>=0&&l<=2&&!this.blocked(g,l,look));if(opts.length)this.setLane(s,opts[Math.floor(Math.random()*opts.length)]);return}
  const balls=g.objs.filter(o=>o.alive&&o.kind==='ball'&&o.y>g.bearY&&o.y-g.bearY<look*1.2).sort((a,b)=>a.y-b.y);
  if(balls.length){const ball=balls[0],step=ball.lane>g.lane?g.lane+1:(ball.lane<g.lane?g.lane-1:g.lane);if(step!==g.lane&&!this.blocked(g,step,look)&&s.skill>.3)this.setLane(s,step)}}
 began(seat,at){const g=this.st[seat.index];this.setLane(seat,at.x<0?g.lane-1:g.lane+1)}
}
Arcade.register('dash',DashGame);
})();
