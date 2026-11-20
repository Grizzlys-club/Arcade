(()=>{
const {Node,Sprite,A,Gfx,Theme,rgba,white,label}=SK;
const manTex=()=>Gfx.texture('snowball_man',48,64,2,c=>{const el=(x,y,w,h)=>{c.beginPath();c.ellipse(x+w/2,y+h/2,w/2,h/2,0,0,7)};
 c.fillStyle='rgb(247,247,247)';el(6,28,36,34);c.fill();el(12,12,24,24);c.fill();c.strokeStyle='rgb(128,191,255)';c.lineWidth=2;el(6,28,36,34);c.stroke();el(12,12,24,24);c.stroke();
 c.fillStyle='rgb(31,31,51)';c.fillRect(14,10,20,4);c.fillRect(18,1,12,10);el(18,19,4,4);c.fill();el(27,19,4,4);c.fill();
 c.fillStyle='#ff9500';c.fillRect(22,24,12,4);c.fillStyle='rgb(31,31,51)';el(21,37,5,5);c.fill();el(21,47,5,5);c.fill()});
class SnowballGame extends MiniScene{
 setupGame(){this.duration=30;const r=this.newRand();this.spawns=[];let t=.5;
  while(t<this.duration-1){const p=t/this.duration,friend=r.chance(.28);this.spawns.push({time:t,x:r.range(-1,1),y:r.range(0,1),friend,life:(1.9-.7*p)*r.range(.85,1.15),vx:r.range(-1,1)*(20+50*p)});t+=(.62-.27*p)*r.range(.8,1.2)}
  this.tsize=Math.min(50,(this.seats[0]?this.seats[0].w:200)*.2);this.st=[];
  for(const s of this.seats){const g={targets:[],balls:[],next:0,cooldown:0,cpuPlan:[]};
   g.aim=new Sprite(Gfx.circle(14,'rgba(0,0,0,0)',s.color),28,28);g.aim.z=80;g.aim.alpha=0;s.field.add(g.aim);
   const bank=new Sprite(Gfx.pill(s.w,26,white(1,.18),white(1,.4),12,false),s.w,26);bank.y=-s.h/2+8;bank.z=3;s.field.add(bank);this.st.push(g);
   const hint=label('ZIEHEN & LOSLASSEN',Math.min(16,s.w*.075),'#fff');hint.y=-s.h/2+60;hint.z=60;s.field.add(hint);hint.run(A.sequence([A.wait(4.4),A.fadeOut(.4),A.remove()]))}}
 origin(s){return{x:0,y:-s.h/2+26}}
 spawn(s,e){const g=this.st[s.index],node=new Node(),ts=this.tsize;let rad=ts*.55;
  if(e.friend){const b=this.makeBear(s,ts*.95,e.vx>0);b.y=-ts*.45;b.startRun();node.add(b);const heart=label('♥',ts*.4,Theme.pink);heart.y=ts*.62;node.add(heart);rad=ts*.5}
  else{const m=new Sprite(manTex(),ts*.8,ts*.8*64/48);node.add(m);const glow=new Sprite(Gfx.glow(),ts*1.5,ts*1.5);glow.color=Theme.blue;glow.cbf=1;glow.blend='add';glow.alpha=.35;glow.z=-1;node.add(glow)}
  const top=s.h/2-50,bottom=-s.h/2+110,hw=s.w/2-ts*.6;node.x=e.x*hw;node.y=bottom+e.y*(top-bottom);node.z=10;node.setScale(.05);node.run(A.scaleTo(1,.15));s.field.add(node);
  const tg={node,friend:e.friend,until:this.elapsed+e.life,vx:e.vx,alive:true,radius:rad};g.targets.push(tg);
  if(s.isCPU){let p=e.friend?(1-s.skill)*.08:.3+.65*s.skill;p=Math.min(p,.95);if(Math.random()<p){const react=.3+(1-s.skill)*.7+Math.random()*.25;if(react<e.life)g.cpuPlan.push([tg,this.elapsed+react])}}}
 throwBall(s,target){const g=this.st[s.index];if(this.elapsed<g.cooldown)return;g.cooldown=this.elapsed+.22;const from=this.origin(s),to={x:target.x,y:Math.max(target.y,from.y+30)};
  const ball=new Sprite(Gfx.ball(8),16,16);ball.color='#fff';ball.cbf=.8;ball.x=from.x;ball.y=from.y;ball.z=50;s.field.add(ball);const dist=Math.hypot(to.x-from.x,to.y-from.y);
  g.balls.push({node:ball,from,to,t0:this.elapsed,dur:.3+dist/700,arc:40+dist*.18,tt:0});Sfx.play('kick');if(!s.isCPU)Haptic.tap('light')}
 land(s,b){const g=this.st[s.index];b.node.removeFromParent();let hit=null,bd=1e9;
  for(const t of g.targets){if(!t.alive)continue;const d=Math.hypot(t.node.x-b.to.x,t.node.y-b.to.y);if(d<t.radius+8&&d<bd){bd=d;hit=t}}
  if(!hit){s.burst(b.to,'#fff',6,45);Sfx.play('tap');return}
  const t=hit;t.alive=false;const p={x:t.node.x,y:t.node.y};
  if(t.friend){this.setScore(s,Math.max(0,s.score-2));s.floatText('-2',p,rgba(1,.3,.3),26);s.flash('#f00',.35);s.shake(7);s.burst(p,Theme.pink,14,90);Sfx.play('wrong');if(!s.isCPU)Haptic.bad()}
  else{this.addScore(s,1);this.addStat('hits',1,s);s.floatText('+1',p,'#fff');s.burst(p,'#fff',20,120);s.burst(p,Theme.blue,10,80);Sfx.play('hit');if(!s.isCPU)Haptic.tap('medium');
   // Extra: Schneewolke
   for(let i=0;i<8;i++){const f=new Sprite(Gfx.dot(),7,7);f.x=p.x;f.y=p.y;f.z=60;f.blend='add';s.field.add(f);const a=Math.random()*6.28;f.run(A.sequence([A.group([A.moveBy(Math.cos(a)*45,Math.sin(a)*45-10,.5),A.fadeOut(.5),A.scaleTo(.2,.5)]),A.remove()]))}}
  t.node.run(A.sequence([A.group([A.scaleXTo(1.4,.08),A.scaleYTo(.3,.08)]),A.fadeOut(.1),A.remove()]))}
 gameUpdate(dt){for(const s of this.seats){const g=this.st[s.index];
   while(g.next<this.spawns.length&&this.spawns[g.next].time<=this.elapsed){this.spawn(s,this.spawns[g.next]);g.next++}
   const hw=s.w/2-this.tsize*.5;
   for(const t of g.targets){if(!t.alive)continue;t.node.x+=t.vx*dt;if(Math.abs(t.node.x)>hw){t.vx=-t.vx;t.node.x=Math.max(-hw,Math.min(hw,t.node.x))}
    if(this.elapsed>=t.until){t.alive=false;t.node.run(A.sequence([A.scaleTo(.05,.12),A.remove()]))}}
   g.targets=g.targets.filter(t=>t.alive);
   const done=[];for(const b of g.balls){const k=Math.min(1,(this.elapsed-b.t0)/b.dur);b.node.x=b.from.x+(b.to.x-b.from.x)*k;b.node.y=b.from.y+(b.to.y-b.from.y)*k+Math.sin(k*Math.PI)*b.arc;b.node.setScale(1.5-.95*k);if(k>=1)done.push(b)}
   for(const b of done)this.land(s,b);g.balls=g.balls.filter(x=>!done.includes(x));
   if(s.isCPU){const rest=[];for(const[t,at]of g.cpuPlan){if(!t.alive)continue;if(this.elapsed>=at&&this.elapsed<g.cooldown)rest.push([t,at]);
     else if(this.elapsed>=at){const o=this.origin(s),flight=.3+Math.hypot(t.node.x,t.node.y-o.y)/700,err=(1-s.skill)*38;this.throwBall(s,{x:t.node.x+t.vx*flight+(Math.random()*2-1)*err,y:t.node.y+(Math.random()*2-1)*err*.6})}
     else rest.push([t,at])}g.cpuPlan=rest}}}
 began(seat,at){const g=this.st[seat.index];g.aim.x=at.x;g.aim.y=at.y;g.aim.alpha=.9}
 moved(seat,at){const g=this.st[seat.index];g.aim.x=at.x;g.aim.y=at.y}
 ended(seat,at){const g=this.st[seat.index];g.aim.alpha=0;this.throwBall(seat,at)}
}
Arcade.register('snowball',SnowballGame);
})();
