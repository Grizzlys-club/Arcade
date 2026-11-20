(()=>{
const {Node,Sprite,A,Gfx,Theme,rgba,white,label}=SK;
const alpha=(c,a)=>c.replace(/[\d.]+\)$/,a+')');
const BR=22;
class SumoGame extends MiniScene{
 static get layout(){return 'arena'}
 static get stripThickness(){return 78}
 setupGame(){this.duration=45;const ar=this.arena;this.center={x:ar.x+ar.w/2,y:ar.y+ar.h/2};this.r0=Math.min(ar.w,ar.h)/2-12;this.radius=this.r0;this.outCount=0;this.fighters=[];
  const aw=Math.floor(ar.w),ah=Math.floor(ar.h);
  const water=new Sprite(Gfx.texture('sumo_water_'+aw+'x'+ah,aw,ah,1,c=>{Gfx.gradientColors(c,rgba(.02,.12,.25),rgba(.01,.05,.14),aw,ah);c.strokeStyle='rgba(77,179,255,.12)';c.lineWidth=2;c.beginPath();for(let y=8;y<ah;y+=22){for(let x=Math.floor(y)%40;x<aw;x+=44){c.moveTo(x,y);c.quadraticCurveTo(x+10,y-5,x+20,y)}}c.stroke()}),ar.w,ar.h);
  water.x=this.center.x;water.y=this.center.y;water.z=-30;this.world.add(water);water.run(A.forever(A.sequence([A.fadeTo(.8,1.4),A.fadeTo(1,1.4)])));
  const d=this.r0*2,iceTex=Gfx.texture('sumo_ice_'+Math.floor(d),d,d,2,c=>{c.save();c.beginPath();c.arc(d/2,d/2,d/2-2,0,7);c.clip();const g=c.createRadialGradient(d*.4,d*.4,0,d/2,d/2,d/2);g.addColorStop(0,'rgb(235,250,255)');g.addColorStop(1,'rgb(158,214,247)');c.fillStyle=g;c.fillRect(0,0,d,d);
   c.strokeStyle='rgba(255,255,255,.6)';c.lineWidth=1.2;c.beginPath();for(let i=0;i<14;i++){const a=i*.9;c.moveTo(d/2+Math.cos(a)*d*.1,d/2+Math.sin(a)*d*.1);c.lineTo(d/2+Math.cos(a+.3)*d*.45,d/2+Math.sin(a+.3)*d*.45)}c.stroke();
   c.strokeStyle='rgba(255,138,0,.5)';c.lineWidth=4;c.beginPath();c.arc(d/2,d/2,d*.15,0,7);c.stroke();c.restore()});
  this.disc=new Sprite(iceTex,d,d);this.disc.x=this.center.x;this.disc.y=this.center.y;this.disc.z=-20;this.world.add(this.disc);
  const logo=new Sprite(Gfx.logo,d*.28,d*.28);logo.alpha=.35;this.disc.add(logo);
  this.discRing=new Sprite(Gfx.circle(this.r0,'rgba(0,0,0,0)','rgba(153,230,255,.9)'),d,d);this.discRing.x=this.center.x;this.discRing.y=this.center.y;this.discRing.z=-19;this.world.add(this.discRing);
  this.discGlow=new Sprite(Gfx.glow(),d*1.25,d*1.25);this.discGlow.color=rgba(.5,.85,1);this.discGlow.cbf=1;this.discGlow.blend='add';this.discGlow.alpha=.3;this.discGlow.x=this.center.x;this.discGlow.y=this.center.y;this.discGlow.z=-21;this.world.add(this.discGlow);
  for(const s of this.seats){const f={node:new Node(),vel:{x:0,y:0},input:{dx:0,dy:0},touch:null,start:{x:0,y:0},outOrder:-1,lastHitBy:-1,lastHitTime:-10,cpuThink:0};
   const dir=s.dirToScene({dx:0,dy:-1});f.pos={x:this.center.x+dir.dx*this.r0*.55,y:this.center.y+dir.dy*this.r0*.55};
   f.ring=new Sprite(Gfx.circle(BR,alpha(s.color,.35),s.color),BR*2,BR*2);f.node.add(f.ring);
   const g=new Sprite(Gfx.glow(),BR*4,BR*4);g.color=s.color;g.cbf=1;g.blend='add';g.alpha=.5;g.z=-1;f.node.add(g);
   f.bear=this.makeBear(s,40,f.pos.x<this.center.x);f.bear.y=-BR*.55;f.bear.z=2;f.node.add(f.bear);f.node.x=f.pos.x;f.node.y=f.pos.y;f.node.z=30;this.world.add(f.node);
   const stick=new Node(),base=new Sprite(Gfx.circle(30,white(1,.08),alpha(s.color,.7)),60,60);stick.add(base);const knob=new Sprite(Gfx.circle(14,s.color,'#fff'),28,28);knob.z=1;stick.add(knob);stick.y=-4;stick.z=420;stick.alpha=s.isCPU?.35:.9;s.node.add(stick);f.stick=stick;f.knob=knob;
   if(!s.isCPU){const hint=label('ZIEHEN = SCHIEBEN',10,white(1,.6));hint.y=-s.h/2+10;hint.z=420;s.node.add(hint);hint.run(A.sequence([A.wait(8),A.fadeOut(.5),A.remove()]))}
   this.fighters.push(f)}}
 began(seat,at,id){const f=this.fighters[seat.index];f.touch=id;f.start={x:at.x,y:at.y};f.input={dx:0,dy:0};f.stick.x=Math.max(-seat.w/2+30,Math.min(seat.w/2-30,at.x));f.stick.y=Math.max(-seat.h/2+30,Math.min(seat.h/2+60,at.y));f.knob.x=0;f.knob.y=0}
 moved(seat,at,id){const f=this.fighters[seat.index];if(f.touch!==id)return;let vx=at.x-f.start.x,vy=at.y-f.start.y;const l=Math.hypot(vx,vy),mx=50;if(l>mx){vx=vx/l*mx;vy=vy/l*mx}f.knob.x=vx*.6;f.knob.y=vy*.6;f.input=seat.dirToScene({dx:vx/mx,dy:vy/mx})}
 ended(seat,at,id){const f=this.fighters[seat.index];if(f.touch!==id)return;f.touch=null;f.input={dx:0,dy:0};f.knob.run(A.moveTo(0,0,.1))}
 gameUpdate(dt){const t=Math.min(1,this.elapsed/(this.duration*.85));this.radius=this.r0*(1-.55*t);this.disc.setScale(this.radius/this.r0);this.discRing.setScale(this.radius/this.r0);this.discGlow.setScale(this.radius/this.r0);
  // Extra: Eis knackt kurz vor dem Rand -> Ring pulsiert rot in der letzten Phase
  if(t>.7){const k=(Math.sin(this.elapsed*8)+1)/2;this.discRing.color=rgba(1,.4+.4*(1-k),.3);this.discRing.cbf=.5*k}
  for(const s of this.seats){if(!s.alive)continue;const f=this.fighters[s.index];if(s.isCPU)this.cpu(s,f,dt);
   f.vel.x+=f.input.dx*620*dt;f.vel.y+=f.input.dy*620*dt;const fr=Math.pow(.35,dt);f.vel.x*=fr;f.vel.y*=fr;const sp=Math.hypot(f.vel.x,f.vel.y);if(sp>340){f.vel.x=f.vel.x/sp*340;f.vel.y=f.vel.y/sp*340}
   f.pos.x+=f.vel.x*dt;f.pos.y+=f.vel.y*dt;if(Math.abs(f.vel.x)>8)f.bear.setFacing(f.vel.x>0);
   // Extra: Eisspur hinter dem Bären
   if(sp>150&&Math.random()<.35){const q=new Sprite(Gfx.dot(),6,6);q.blend='add';q.alpha=.5;q.x=f.pos.x;q.y=f.pos.y-BR*.5;q.z=-10;q.color=s.color;q.cbf=1;this.world.add(q);q.run(A.sequence([A.group([A.fadeOut(.4),A.scaleTo(.2,.4)]),A.remove()]))}}
  const alive=this.seats.filter(s=>s.alive);for(let i=0;i<alive.length;i++)for(let j=i+1;j<alive.length;j++)this.collide(alive[i],alive[j]);
  for(const s of this.seats){if(!s.alive)continue;const f=this.fighters[s.index];f.node.x=f.pos.x;f.node.y=f.pos.y;if(Math.hypot(f.pos.x-this.center.x,f.pos.y-this.center.y)>this.radius+BR*.2)this.fall(s,f)}
  if(this.aliveSeats.length<=1)this.finishGame(this.finalScores())}
 collide(a,b){const fa=this.fighters[a.index],fb=this.fighters[b.index],dx=fb.pos.x-fa.pos.x,dy=fb.pos.y-fa.pos.y,d=Math.hypot(dx,dy),minD=BR*2;if(d>=minD||d<=.001)return;
  const nx=dx/d,ny=dy/d,push=(minD-d)/2;fa.pos.x-=nx*push;fa.pos.y-=ny*push;fb.pos.x+=nx*push;fb.pos.y+=ny*push;const rv=(fb.vel.x-fa.vel.x)*nx+(fb.vel.y-fa.vel.y)*ny;
  if(rv<0){const j=-(1+1.35)*rv/2;fa.vel.x-=j*nx;fa.vel.y-=j*ny;fb.vel.x+=j*nx;fb.vel.y+=j*ny;
   if(-rv>120){Sfx.play('hit');if(!a.isCPU||!b.isCPU)Haptic.tap('medium');const mid={x:(fa.pos.x+fb.pos.x)/2,y:(fa.pos.y+fb.pos.y)/2};this.spark(mid,-rv);fa.bear.squash();fb.bear.squash();
    if(-rv>260){this.world.run(A.sequence([A.moveBy(3,2,.025),A.moveBy(-6,-4,.04),A.moveBy(3,2,.03)]))}}else Sfx.play('bounce');
   fa.lastHitBy=b.index;fa.lastHitTime=this.elapsed;fb.lastHitBy=a.index;fb.lastHitTime=this.elapsed}}
 spark(p,power){const n=8+Math.min(10,Math.floor(power/40));for(let i=0;i<n;i++){const d=new Sprite(Gfx.dot(),6,6);d.color='#fff';d.cbf=1;d.blend='add';d.x=p.x;d.y=p.y;d.z=40;this.world.add(d);const a=Math.random()*6.28,r=20+Math.random()*(40+power*.1);d.run(A.sequence([A.group([A.moveBy(Math.cos(a)*r,Math.sin(a)*r,.3),A.fadeOut(.3)]),A.remove()]))}
  const ring=new Sprite(Gfx.circle(12,'rgba(0,0,0,0)','#fff'),24,24);ring.blend='add';ring.x=p.x;ring.y=p.y;ring.z=40;this.world.add(ring);ring.run(A.sequence([A.group([A.scaleTo(3,.25),A.fadeOut(.25)]),A.remove()]))}
 fall(s,f){f.outOrder=this.outCount++;s.knockOut('PLATSCH!');Sfx.play('miss');if(!s.isCPU)Haptic.bad();
  f.node.run(A.sequence([A.group([A.scaleTo(.2,.5),A.fadeOut(.5),A.rotateBy(3,.5)]),A.remove()]));
  const ring=new Sprite(Gfx.circle(10,'rgba(0,0,0,0)','rgb(153,230,255)'),20,20);ring.x=f.pos.x;ring.y=f.pos.y;ring.z=25;this.world.add(ring);ring.run(A.sequence([A.group([A.scaleTo(5,.6),A.fadeOut(.6)]),A.remove()]));
  for(let i=0;i<20;i++){const d=new Sprite(Gfx.dot(),7,7);d.color=rgba(.6,.9,1);d.cbf=1;d.x=f.pos.x;d.y=f.pos.y;d.z=26;this.world.add(d);const a=Math.random()*6.28;d.run(A.sequence([A.group([A.moveBy(Math.cos(a)*55,Math.sin(a)*55+30,.5),A.fadeOut(.5)]),A.remove()]))}
  if(f.lastHitBy>=0&&this.elapsed-f.lastHitTime<2.5&&this.seats[f.lastHitBy].alive){const k=this.seats[f.lastHitBy];this.addScore(k,1);this.addStat('hits',1,k);k.banner('K.O.!','#ff0',30,.6);k.flash('#ff0',.2)}
  this.bannerAll(s.name.toUpperCase()+' RAUS',s.color,26,.6)}
 finalScores(){return this.seats.map(s=>{const f=this.fighters[s.index];if(f.outOrder>=0)return f.outOrder*100+s.score;const d=Math.hypot(f.pos.x-this.center.x,f.pos.y-this.center.y);return this.n*100+Math.floor(Math.max(0,99-d/Math.max(1,this.r0)*99))})}
 timeUp(){this.finishGame(this.finalScores())}
 cpu(s,f,dt){f.cpuThink-=dt;if(f.cpuThink>0)return;f.cpuThink=.08+(1-s.skill)*.25;let target=null,bd=1e9;
  for(const o of this.seats){if(!o.alive||o.index===s.index)continue;const fo=this.fighters[o.index],d=Math.hypot(fo.pos.x-f.pos.x,fo.pos.y-f.pos.y);if(d<bd){bd=d;target=fo}}
  let ax=0,ay=0;if(target){const ox=target.pos.x-this.center.x,oy=target.pos.y-this.center.y,ol=Math.max(1,Math.hypot(ox,oy)),ax0=target.pos.x-ox/ol*8,ay0=target.pos.y-oy/ol*8;ax=ax0-f.pos.x;ay=ay0-f.pos.y;const l=Math.max(1,Math.hypot(ax,ay));ax/=l;ay/=l}
  const cx=this.center.x-f.pos.x,cy=this.center.y-f.pos.y,cd=Math.hypot(cx,cy),danger=cd/Math.max(1,this.radius);
  if(danger>.62){const w=(.5+s.skill)*(danger-.55)*4;ax+=cx/Math.max(1,cd)*w;ay+=cy/Math.max(1,cd)*w}
  const l=Math.max(.001,Math.hypot(ax,ay)),st=.55+.45*s.skill,nz=(1-s.skill)*.5;f.input={dx:ax/l*st+(Math.random()*2-1)*nz,dy:ay/l*st+(Math.random()*2-1)*nz};f.knob.x=0;f.knob.y=0}
}
Arcade.register('sumo',SumoGame);
})();
