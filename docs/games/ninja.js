(()=>{
const {Node,Sprite,A,Gfx,Theme,rgba,white,label}=SK;
const rr=(a,b)=>a+Math.random()*(b-a);
const puckTex=()=>Gfx.texture('ninja_puck',48,48,2,c=>{c.fillStyle='rgb(20,20,20)';c.beginPath();c.arc(24,24,22,0,7);c.fill();c.strokeStyle='rgb(140,140,140)';c.lineWidth=3;c.beginPath();c.arc(24,24,19,0,7);c.stroke();c.fillStyle=Theme.orange;c.beginPath();c.arc(24,24,7,0,7);c.fill()});
const goldTex=()=>Gfx.texture('ninja_gold',48,48,2,c=>{c.fillStyle='rgb(255,204,26)';c.beginPath();c.arc(24,24,22,0,7);c.fill();c.strokeStyle='rgb(255,255,179)';c.lineWidth=3;c.beginPath();c.arc(24,24,19,0,7);c.stroke();c.fillStyle='rgb(179,115,0)';c.beginPath();for(let i=0;i<10;i++){const rad=i%2===0?12:5,a=i*Math.PI/5-Math.PI/2,x=24+Math.cos(a)*rad,y=24+Math.sin(a)*rad;i?c.lineTo(x,y):c.moveTo(x,y)}c.closePath();c.fill()});
const cardTex=()=>Gfx.texture('ninja_card',36,48,2,c=>{SK.rr(c,2,2,32,44,5);c.fillStyle='rgb(242,26,31)';c.fill();c.strokeStyle='#fff';c.lineWidth=2.5;c.stroke()});
class NinjaGame extends MiniScene{
 setupGame(){this.duration=30;this.clock=0;this.st=this.seats.map(()=>({rand:this.newRand(),nextSpawn:.6,items:[],trail:[],trailDots:[],last:null,comboCount:0,cpuSwipeT:0}));
  for(const s of this.seats){const g=this.st[s.index];
   for(let i=0;i<5;i++){const line=new Sprite(null,s.w,2,s.color.replace(/[\d.]+\)$/,'.06)'));line.y=-s.h/2+(i+1)*s.h/6;line.z=-5;s.field.add(line)}
   for(let i=0;i<14;i++){const d=new Sprite(Gfx.glow(),22,22);d.color=s.color;d.cbf=.6;d.blend='add';d.z=50;d.alpha=0;d.setScale(1-i*.05);s.field.add(d);g.trailDots.push(d)}
   const hint=label('WISCHEN! ⚔️',Math.min(20,s.w*.09),'#fff');hint.z=60;s.field.add(hint);hint.run(A.sequence([A.wait(4.5),A.fadeOut(.4),A.remove()]));
   const warn=label('Rote Karten meiden!',Math.min(13,s.w*.065),rgba(1,.4,.4));warn.y=-26;warn.z=60;s.field.add(warn);warn.run(A.sequence([A.wait(4.5),A.fadeOut(.4),A.remove()]))}}
 gravity(s){return s.h*1.55}
 spawn(s){const g=this.st[s.index],r=g.rand,count=r.chance(.3)?(r.chance(.4)?3:2):1;
  for(let k=0;k<count;k++){const roll=r.double(),kind=roll<.14?'card':(roll<.24?'gold':(roll<.6?'puck':'ball')),x=r.range(-.36,.36)*s.w,apex=r.range(.55,.88)*s.h,gr=this.gravity(s),vy=Math.sqrt(2*gr*apex),vx=(-x*.9+r.range(-.15,.15)*s.w)/1.8,rad=Math.min(22,s.w*.1);let node;
   if(kind==='puck')node=new Sprite(puckTex(),rad*2,rad*2);else if(kind==='ball')node=new Sprite(Gfx.ball(20),rad*1.8,rad*1.8);else if(kind==='gold')node=new Sprite(goldTex(),rad*2,rad*2);else node=new Sprite(cardTex(),rad*1.4,rad*1.9);
   node.z=10;const pos={x,y:-s.h/2-rad};node.x=pos.x;node.y=pos.y;s.field.add(node);
   if(kind==='gold'||kind==='card'){const glow=new Sprite(Gfx.glow(),rad*3.6,rad*3.6);glow.color=kind==='gold'?'#ff0':'#f00';glow.cbf=1;glow.blend='add';glow.alpha=.55;glow.z=-1;node.add(glow)}
   g.items.push({node,kind,pos,vel:{x:vx,y:vy},spin:r.range(-5,5),alive:true,cpuPlan:null,cpuDecided:false,r:rad})}
  Sfx.play('jump');g.nextSpawn=this.clock+Math.max(.45,1.05-this.clock*.02)*r.range(.8,1.2)}
 slice(s,it,dir){if(!it.alive)return;it.alive=false;const g=this.st[s.index];
  if(it.kind==='card'){this.setScore(s,Math.max(0,s.score-5));s.flash('#f00',.5);s.shake(9);s.floatText('-5',it.pos,rgba(1,.3,.3),28);Sfx.play('wrong');if(!s.isCPU)Haptic.bad();g.comboCount=0}
  else if(it.kind==='gold'){this.addScore(s,3);this.addStat('hits',1,s);s.floatText('+3',it.pos,'#ff0',26);Sfx.play('coin');if(!s.isCPU)Haptic.good();g.comboCount++;s.flash('#ff0',.1)}
  else{this.addScore(s,1);this.addStat('hits',1,s);s.floatText('+1',it.pos,'#fff',20);Sfx.play('hit');if(!s.isCPU)Haptic.tap();g.comboCount++}
  s.burst(it.pos,it.kind==='card'?'#f00':(it.kind==='gold'?'#ff0':s.color),it.kind==='gold'?20:14,110);
  const len=Math.max(.001,Math.hypot(dir.x,dir.y)),nx=-dir.y/len,ny=dir.x/len,ang=Math.atan2(dir.y,dir.x);
  for(const side of[-1,1]){const half=new Sprite(it.node.texture,it.node.w,it.node.h);half.x=it.pos.x;half.y=it.pos.y;half.z=9;half.sx=.55;half.rot=ang;half.alpha=.9;s.field.add(half);
   half.run(A.sequence([A.group([A.moveBy(nx*side*40,ny*side*40-60,.5),A.rotateBy(side*3,.5),A.fadeOut(.5)]),A.remove()]))}
  it.node.removeFromParent();
  const slash=new Sprite(null,it.r*3.4,3,'#fff');slash.x=it.pos.x;slash.y=it.pos.y;slash.rot=ang;slash.z=60;slash.blend='add';s.field.add(slash);slash.run(A.sequence([A.group([A.fadeOut(.25),A.scaleXTo(1.6,.25)]),A.remove()]));
  // Extra: Saft-Spritzer
  for(let i=0;i<6;i++){const d=new Sprite(Gfx.dot(),5,5);d.color=it.kind==='card'?'#f44':'#fff';d.cbf=1;d.blend='add';d.x=it.pos.x;d.y=it.pos.y;d.z=58;s.field.add(d);const a=ang+(Math.random()-.5)*.5+(Math.random()<.5?0:Math.PI),dd=30+Math.random()*50;d.run(A.sequence([A.group([A.moveBy(Math.cos(a)*dd,Math.sin(a)*dd,.3),A.fadeOut(.3)]),A.remove()]))}}
 endSwipe(s){const g=this.st[s.index];if(g.comboCount>=3){const bonus=g.comboCount-2;this.addScore(s,bonus);s.banner('COMBO x'+g.comboCount+'  +'+bonus,'#ff0',26,.5);s.flash('#ff0',.15);Sfx.play('fanfare')}g.comboCount=0;g.last=null}
 swipe(s,a,b){const g=this.st[s.index],dx=b.x-a.x,dy=b.y-a.y,sl2=dx*dx+dy*dy;
  for(const it of g.items){if(!it.alive)continue;let t=0;if(sl2>.0001){t=((it.pos.x-a.x)*dx+(it.pos.y-a.y)*dy)/sl2;t=Math.max(0,Math.min(1,t))}
   const cx=a.x+dx*t,cy=a.y+dy*t;if(Math.hypot(it.pos.x-cx,it.pos.y-cy)<it.r+6)this.slice(s,it,{x:dx,y:dy})}
  g.trail.push([b,this.clock])}
 gameUpdate(dt){this.clock=this.elapsed;
  for(const s of this.seats){const g=this.st[s.index];if(this.clock>=g.nextSpawn&&this.duration-this.elapsed>1.2)this.spawn(s);const gr=this.gravity(s);
   for(const it of g.items){if(!it.alive)continue;it.vel.y-=gr*dt;it.pos.x+=it.vel.x*dt;it.pos.y+=it.vel.y*dt;it.node.x=it.pos.x;it.node.y=it.pos.y;it.node.rot+=it.spin*dt;
    if(it.pos.y<-s.h/2-40&&it.vel.y<0){it.alive=false;it.node.removeFromParent()}if(s.isCPU&&it.alive)this.cpuThink(s,it)}
   g.items=g.items.filter(i=>i.alive);g.trail=g.trail.filter(t=>this.clock-t[1]<=.18);
   g.trailDots.forEach((dot,i)=>{const idx=g.trail.length-1-i;if(idx>=0){dot.x=g.trail[idx][0].x;dot.y=g.trail[idx][0].y;dot.alpha=Math.max(0,1-(this.clock-g.trail[idx][1])/.18)}else dot.alpha=0});
   if(s.isCPU&&g.cpuSwipeT>0){g.cpuSwipeT-=dt;if(g.cpuSwipeT<=0)this.endSwipe(s)}}}
 cpuThink(s,it){if(!it.cpuDecided&&it.vel.y<it.r*6){it.cpuDecided=true;const p=it.kind==='card'?(1-s.skill)*.18:.4+.55*s.skill;if(Math.random()<p)it.cpuPlan=this.elapsed+rr(.05,.15+(1-s.skill)*.35)}
  if(it.cpuPlan!==null&&this.elapsed>=it.cpuPlan&&it.alive){it.cpuPlan=null;const ang=Math.random()*6.28,a={x:it.pos.x-Math.cos(ang)*40,y:it.pos.y-Math.sin(ang)*40},b={x:it.pos.x+Math.cos(ang)*40,y:it.pos.y+Math.sin(ang)*40},g=this.st[s.index];g.trail.push([a,this.clock]);this.swipe(s,a,b);g.cpuSwipeT=.3}}
 began(seat,at){const g=this.st[seat.index];g.last={x:at.x,y:at.y};g.comboCount=0;g.trail.push([{x:at.x,y:at.y},this.clock])}
 moved(seat,at){const g=this.st[seat.index],last=g.last;if(!last)return;if(Math.hypot(at.x-last.x,at.y-last.y)<2)return;this.swipe(seat,last,at);g.last={x:at.x,y:at.y}}
 ended(seat){this.endSwipe(seat)}
}
Arcade.register('ninja',NinjaGame);
})();
