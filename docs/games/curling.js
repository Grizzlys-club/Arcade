(()=>{
const {Node,Sprite,A,Gfx,Theme,rgba,white,label,Rand}=SK;
const rr=(a,b)=>a+Math.random()*(b-a),MU=90,MAXS=5;
const al=(c,a)=>c.replace(/[\d.]+\)$/,a+')');
class CurlingGame extends MiniScene{
 static get layout(){return 'turns'}
 setupGame(){this.turnWait=0;this.pads=[];this.finishing=false;for(const s of this.seats){const p={seat:s,stones:[],thrown:0,mode:'ready',cur:null,timer:0,tx:0,ty:0,R:0,r:12,startY:0,dots:[],ghost:null,pull:null,counter:null,hint:null,anchor:null,touch:null,trailT:0,bear:null,lastHit:-1,idle:0,cpuWait:.8,slideT:0,prevTotal:0};this.pads.push(p);this.buildP(p);this.spawnStone(p)}this.setActiveSeat(0)}
 buildP(p){const s=p.seat,w=s.w,h=s.h;p.r=w<250?11:13;p.R=Math.min(w*.36,56);p.tx=0;p.ty=h/2-32-p.R;p.startY=-h/2+p.r+32;
  const ice=new Sprite(this.iceTex(w-6,h-6,p.ty,p.R,p.r,s.index),w-6,h-6);ice.z=-30;s.field.add(ice);
  const glow=new Sprite(Gfx.glow(),p.R*3,p.R*3);glow.color=s.color;glow.cbf=1;glow.blend='add';glow.alpha=.5;glow.x=p.tx;glow.y=p.ty;glow.z=-29;s.field.add(glow);glow.run(A.forever(A.sequence([A.fadeTo(.28,1.1),A.fadeTo(.55,1.1)])));
  const rings=new Sprite(this.ringTex(p.R,s.index,s.color),p.R*2,p.R*2);rings.x=p.tx;rings.y=p.ty;rings.z=-28;s.field.add(rings);
  for(const [t,f] of [['1',.84],['2',.54],['3',.29]]){const l=label(t,9,white(1,.75));l.x=p.tx+p.R*f;l.y=p.ty;l.z=-27;s.field.add(l)}
  const five=label('5',10,white(.1,.8));five.x=p.tx;five.y=p.ty;five.z=-27;s.field.add(five);
  const c=label('STEIN 1/'+MAXS,w<250?11:13,s.color);c.ha='left';c.x=-w/2+14;c.y=h/2-34;c.z=400;c.alpha=.95;s.node.add(c);p.counter=c;
  for(let i=0;i<14;i++){const d=new Sprite(Gfx.dot(),6,6);d.color='#fff';d.cbf=1;d.blend='add';d.alpha=0;d.z=20;s.field.add(d);p.dots.push(d)}
  const g=new Sprite(Gfx.circle(p.r,white(1,.12),'#fff'),p.r*2,p.r*2);g.alpha=0;g.z=19;s.field.add(g);p.ghost=g;
  const pl=new Sprite(Gfx.rect(4,4,'#fff',2),4,10);pl.ay=0;pl.color=s.color;pl.cbf=1;pl.blend='add';pl.alpha=0;pl.z=18;s.field.add(pl);p.pull=pl;
  const hl=label('ZIEHEN & LOSLASSEN',w<250?11:14,'#fff');hl.y=p.startY+50;hl.z=60;s.field.add(hl);hl.run(A.forever(A.sequence([A.fadeTo(.4,.5),A.fadeTo(1,.5)])));hl.run(A.sequence([A.wait(6),A.fadeOut(.3),A.remove()]),'hintOut');p.hint=hl;
  const bear=this.makeBear(s,w<250?40:50,true);bear.x=-w/2+(w<250?24:34);bear.y=-h/2+8;bear.z=30;s.field.add(bear);bear.startBob(2,.5);p.bear=bear}
 iceTex(w,h,ty,R,r,idx){w=Math.floor(w);h=Math.floor(h);return Gfx.texture('curl_ice_'+w+'_'+h+'_'+idx,w,h,1.5,c=>{c.save();c.beginPath();SK.rr(c,0,0,w,h,15);c.clip();Gfx.gradientColors(c,rgba(.2,.36,.56),rgba(.07,.12,.24),w,h);const rnd=new Rand(77);
  for(let i=0;i<26;i++){const x=rnd.range(0,w),y0=rnd.range(0,h),len=rnd.range(30,140);c.strokeStyle='rgba(204,242,255,'+rnd.range(.04,.16)+')';c.lineWidth=rnd.range(.6,1.8);c.beginPath();c.moveTo(x,y0);c.lineTo(x+rnd.range(-6,6),y0+len);c.stroke()}
  const cy=h/2-ty,g=c.createRadialGradient(w/2,cy,0,w/2,cy,R*2.2);g.addColorStop(0,'rgba(255,255,255,.16)');g.addColorStop(1,'rgba(255,255,255,0)');c.fillStyle=g;c.fillRect(0,0,w,h);
  c.strokeStyle='rgba(255,255,255,.14)';c.lineWidth=1;c.beginPath();c.moveTo(w/2,0);c.lineTo(w/2,h);c.moveTo(0,cy);c.lineTo(w,cy);c.stroke();
  c.strokeStyle='rgba(255,102,102,.45)';c.lineWidth=1.5;const by=h/2-(ty+R+r*.5);c.beginPath();c.moveTo(0,by);c.lineTo(w,by);c.stroke();
  c.strokeStyle='rgba(255,255,255,.3)';c.beginPath();c.moveTo(12,h-22);c.lineTo(w-12,h-22);c.stroke();c.restore()})}
 ringTex(R,idx,color){const d=Math.ceil(R*2);return Gfx.texture('curl_rings_'+Math.floor(R)+'_'+idx+'_'+color,d,d,2,c=>{const radii=[1,.68,.4,.18],cols=[al(color,.5),white(1,.38),al(color,.85),white(1,.95)];
  radii.forEach((f,i)=>{const rr2=R*f;c.save();c.globalCompositeOperation='destination-out';c.beginPath();c.arc(R,R,rr2,0,7);c.fill();c.restore();c.fillStyle=cols[i];c.beginPath();c.arc(R,R,rr2,0,7);c.fill();c.strokeStyle='rgba(255,255,255,.7)';c.lineWidth=1.2;c.beginPath();c.arc(R,R,rr2-.6,0,7);c.stroke()})})}
 stoneTex(r,idx,color){const d=r*2;return Gfx.texture('curl_stone_'+Math.floor(r)+'_'+idx+'_'+color,d,d,3,c=>{c.save();c.beginPath();c.arc(r,r,r-.5,0,7);c.clip();Gfx.gradientColors(c,white(.72),white(.32),d,d);c.restore();
  c.strokeStyle=color;c.lineWidth=Math.max(2,r*.22);c.beginPath();c.arc(r,r,r-.5-r*.11,0,7);c.stroke();const hr=r*.5;c.fillStyle=color;c.beginPath();c.arc(r,r,hr,0,7);c.fill();c.fillStyle='rgba(255,255,255,.85)';c.fillRect(r-hr*.9,r-1.2,hr*1.8,2.4);
  c.strokeStyle='rgba(26,26,26,.8)';c.lineWidth=1;c.beginPath();c.arc(r,r,r-.5,0,7);c.stroke()})}
 spawnStone(p){const s=p.seat,st={node:new Node(),spin:new Node(),pos:{x:0,y:p.startY},vel:{x:0,y:0},out:false,get moving(){return this.vel.x!==0||this.vel.y!==0}};st.node.x=0;st.node.y=p.startY;st.node.z=10;
  const sh=new Sprite(Gfx.shadow(),p.r*3.2,p.r*1.3);sh.x=2;sh.y=-p.r*.9;sh.z=-2;st.node.add(sh);const gl=new Sprite(Gfx.glow(),p.r*3.6,p.r*3.6);gl.color=s.color;gl.cbf=1;gl.blend='add';gl.alpha=.5;gl.z=-1;st.node.add(gl);
  st.spin.add(new Sprite(this.stoneTex(p.r,s.index,s.color),p.r*2,p.r*2));st.node.add(st.spin);const hi=new Sprite(Gfx.dot(),p.r*.7,p.r*.7);hi.alpha=.35;hi.x=-p.r*.35;hi.y=p.r*.4;hi.z=2;st.node.add(hi);
  st.node.setScale(.2);st.node.run(A.scaleTo(1,.2));s.field.add(st.node);p.stones.push(st);p.cur=st;p.mode='ready';p.idle=0;p.cpuWait=.7+Math.random()*.5;p.anchor=null;p.touch=null;this.updCounter(p)}
 updCounter(p){if(p.mode==='done')p.counter.text='FERTIG';else{const num=p.mode==='ready'?p.thrown+1:p.thrown;p.counter.text='STEIN '+Math.min(MAXS,Math.max(1,num))+'/'+MAXS}}
 vmax(p){return Math.sqrt(2*MU*(p.ty-p.startY))*1.35}
 aim(p,a,b){const px=a.x-b.x,py=a.y-b.y;if(py<=2)return{dir:{x:0,y:1},pow:0};const mp=Math.min(p.seat.h*.28,100),len=Math.hypot(px,py),pw=Math.min(1,len/mp);let ang=Math.max(-.8,Math.min(.8,Math.atan2(px,py)));return{dir:{x:Math.sin(ang),y:Math.cos(ang)},pow:pw}}
 showAim(p,dir,pw){const st=p.cur;if(!st)return;const v=this.vmax(p)*pw,L=v*v/(2*MU),n=p.dots.length;
  p.dots.forEach((d,i)=>{const dist=15*(i+1);if(pw<.12||dist>L-8)d.alpha=0;else{d.x=st.pos.x+dir.x*dist;d.y=st.pos.y+dir.y*dist;d.alpha=.9*(1-i/(n+2));d.color=p.seat.color}});
  const g=p.ghost;if(pw<.12)g.alpha=0;else{g.x=st.pos.x+dir.x*L;g.y=st.pos.y+dir.y*L;g.alpha=.9;const over=g.y>p.ty+p.R+p.r*.5;g.color=over?'#f00':'#fff';g.cbf=over?.8:0}
  const pl=p.pull,len=pw*Math.min(p.seat.h*.28,100)*.7;pl.alpha=pw<.05?0:.8;pl.x=st.pos.x;pl.y=st.pos.y;pl.w=4;pl.h=len;pl.rot=-Math.atan2(dir.x,dir.y)+Math.PI}
 hideAim(p){p.dots.forEach(d=>d.alpha=0);p.ghost.alpha=0;p.pull.alpha=0}
 launch(p,dir,speed){const st=p.cur;if(!st||p.mode!=='ready')return;st.vel={x:dir.x*speed,y:dir.y*speed};p.mode='sliding';p.thrown++;p.slideT=0;p.prevTotal=this.total(p);if(p.hint){p.hint.removeAction('hintOut');p.hint.run(A.sequence([A.fadeOut(.2),A.remove()]));p.hint=null}
  p.bear.squash();Sfx.play('kick');if(!p.seat.isCPU)Haptic.tap('medium');this.updCounter(p);this.hideAim(p)}
 cpuThrow(p){const sk=p.seat.skill,dx=p.tx,dy=p.ty-p.startY,dist=Math.hypot(dx,dy);let ang=Math.atan2(dx,dy);ang+=rr(-1,1)*(1-sk)*.16;const f=1+rr(-1,1)*(1-sk)*.2;this.launch(p,{x:Math.sin(ang),y:Math.cos(ang)},Math.sqrt(2*MU*dist)*f)}
 began(seat,at,id){const p=this.pads[seat.index];if(p.mode!=='ready'||p.anchor)return;p.anchor={x:at.x,y:at.y};p.touch=id;p.idle=0;Haptic.tap('light')}
 moved(seat,at,id){const p=this.pads[seat.index];if(p.mode!=='ready'||p.touch!==id||!p.anchor)return;const r=this.aim(p,p.anchor,at);this.showAim(p,r.dir,r.pow)}
 ended(seat,at,id){const p=this.pads[seat.index];if(p.mode!=='ready'||p.touch!==id||!p.anchor)return;const a=p.anchor;p.anchor=null;p.touch=null;const r=this.aim(p,a,at);
  if(r.pow<.12){this.hideAim(p);if(Math.hypot(at.x-a.x,at.y-a.y)>8)seat.floatText('ZIEHEN!',{x:0,y:p.startY+30},'#fff',14);return}this.launch(p,r.dir,this.vmax(p)*r.pow)}
 advanceTurn(){const n=this.seats.length;for(let k=1;k<=Math.max(1,n);k++){const j=(this.activeSeatIndex+k)%n;if(this.pads[j].mode!=='done'){this.pads[j].idle=0;this.pads[j].cpuWait=.8+Math.random()*.5;this.setActiveSeat(j);return}}}
 gameUpdate(dt){const p=this.pads[this.activeSeatIndex];
  if(p.mode==='ready'){p.idle+=dt;if(p.seat.isCPU){p.cpuWait-=dt;if(p.cpuWait<=0)this.cpuThrow(p)}else if(p.idle>14&&!p.anchor){const ang=rr(-1,1)*.7*.2,v=Math.sqrt(2*MU*(p.ty-p.startY))*rr(.85,1.1);this.launch(p,{x:Math.sin(ang),y:Math.cos(ang)},v)}}
  else if(p.mode==='sliding'){p.slideT+=dt;this.phys(p,dt);this.trail(p,dt);if(p.stones.every(s=>!s.moving)||p.slideT>9){for(const s of p.stones)s.vel={x:0,y:0};p.mode='settling';p.timer=.45}}
  else if(p.mode==='settling'){p.timer-=dt;if(p.timer<=0)this.evaluate(p)}
  if(!this.finishing&&this.pads[this.activeSeatIndex].mode==='done'){this.turnWait+=dt;if(this.turnWait>1.1){this.turnWait=0;this.advanceTurn()}}
  if(!this.finishing&&this.elapsed>70*Math.max(1,this.seats.length))this.finishAll()}
 phys(p,dt){const sub=2,h=dt/sub,w=p.seat.w,hh=p.seat.h,r=p.r,outY=p.ty+p.R+r*.5;
  for(let k=0;k<sub;k++){for(const st of p.stones){if(st.out||!st.moving)continue;let sp=Math.hypot(st.vel.x,st.vel.y);const nsp=Math.max(0,sp-MU*h);if(nsp<7){st.vel={x:0,y:0};continue}const kk=nsp/sp;st.vel.x*=kk;st.vel.y*=kk;st.pos.x+=st.vel.x*h;st.pos.y+=st.vel.y*h;
    if(st.pos.x<-w/2+r+3){st.pos.x=-w/2+r+3;st.vel.x=Math.abs(st.vel.x)*.6;this.wallFx(p)}if(st.pos.x>w/2-r-3){st.pos.x=w/2-r-3;st.vel.x=-Math.abs(st.vel.x)*.6;this.wallFx(p)}
    if(st.pos.y<-hh/2+r+3){st.pos.y=-hh/2+r+3;st.vel.y=Math.abs(st.vel.y)*.6}if(st.pos.y>outY)this.knockOutStone(p,st)}
   const live=p.stones.filter(s=>!s.out);for(let i=0;i<live.length;i++)for(let j=i+1;j<live.length;j++){const a=live[i],b=live[j];if(!a.moving&&!b.moving)continue;let dx=b.pos.x-a.pos.x,dy=b.pos.y-a.pos.y,d=Math.hypot(dx,dy);if(d>=2*r)continue;if(d<.001){dx=0;dy=1;d=1}
    const nx=dx/d,ny=dy/d,ov=(2*r-d)/2;a.pos.x-=nx*ov;a.pos.y-=ny*ov;b.pos.x+=nx*ov;b.pos.y+=ny*ov;const vr=(a.vel.x-b.vel.x)*nx+(a.vel.y-b.vel.y)*ny;
    if(vr>0){const j2=vr*1.85/2;a.vel.x-=j2*nx;a.vel.y-=j2*ny;b.vel.x+=j2*nx;b.vel.y+=j2*ny;if(vr>25)this.clack(p,{x:(a.pos.x+b.pos.x)/2,y:(a.pos.y+b.pos.y)/2},vr)}}}
  for(const st of p.stones){if(st.out)continue;st.node.x=st.pos.x;st.node.y=st.pos.y;if(st.moving){const sp=Math.hypot(st.vel.x,st.vel.y);st.spin.rot+=dt*(.8+sp*.004)}}}
 wallFx(p){if(this.elapsed-p.lastHit>.1){p.lastHit=this.elapsed;Sfx.play('bounce')}}
 clack(p,pt,str){if(this.elapsed-p.lastHit<.07)return;p.lastHit=this.elapsed;Sfx.play('hit');p.seat.burst(pt,rgba(.8,.95,1),str>80?14:6,str>80?90:70);
  if(str>70){p.seat.shake(3);if(!p.seat.isCPU)Haptic.tap('medium');const ring=new Sprite(Gfx.circle(10,'rgba(0,0,0,0)','#cff'),20,20);ring.blend='add';ring.x=pt.x;ring.y=pt.y;ring.z=25;p.seat.field.add(ring);ring.run(A.sequence([A.group([A.scaleTo(3,.3),A.fadeOut(.3)]),A.remove()]))}else if(!p.seat.isCPU)Haptic.tap('light')}
 knockOutStone(p,st){st.out=true;st.vel={x:0,y:0};p.seat.floatText('RAUS',{x:st.pos.x,y:Math.min(st.pos.y,p.seat.h/2-50)},white(.85),15);Sfx.play('miss');st.node.run(A.sequence([A.group([A.fadeOut(.3),A.moveBy(0,24,.3),A.scaleTo(.5,.3)]),A.remove()]))}
 trail(p,dt){const st=p.cur;if(!st||!st.moving)return;p.trailT-=dt;if(p.trailT>0)return;p.trailT=.03;const sp=Math.hypot(st.vel.x,st.vel.y),t=new Sprite(Gfx.dot(),p.r*1.1,p.r*1.1);t.color=p.seat.color;t.cbf=1;t.blend='add';t.alpha=Math.min(.7,sp/160);t.x=st.pos.x;t.y=st.pos.y;t.z=3;p.seat.field.add(t);t.run(A.sequence([A.group([A.fadeOut(.45),A.scaleTo(.3,.45)]),A.remove()]));
  if(Math.random()<.25){const a=Math.random()*6.28,sk=new Sprite(Gfx.dot(),3,3);sk.blend='add';sk.x=st.pos.x-st.vel.x*.01;sk.y=st.pos.y-st.vel.y*.01;sk.z=4;p.seat.field.add(sk);sk.run(A.sequence([A.group([A.moveBy(Math.cos(a)*14,Math.sin(a)*14,.35),A.fadeOut(.35)]),A.remove()]))}}
 points(p,st){if(st.out)return 0;const d=Math.hypot(st.pos.x-p.tx,st.pos.y-p.ty);if(d<=p.R*.18+2)return 5;if(d<=p.R*.4)return 3;if(d<=p.R*.68)return 2;if(d<=p.R)return 1;return 0}
 total(p){return p.stones.reduce((a,s)=>a+this.points(p,s),0)}
 evaluate(p){const s=p.seat,tot=this.total(p),mine=p.cur?this.points(p,p.cur):0,pos=p.cur?p.cur.pos:{x:0,y:0},wasOut=p.cur?p.cur.out:false;
  if(!wasOut){if(mine===5){s.banner('VOLLTREFFER!','#ff0',34,.7);s.flash('#ff0',.3);s.burst({x:p.tx,y:p.ty},'#ff0',26,160);s.floatText('+5',pos,'#ff0',28);Sfx.play('coin');Haptic.good();p.bear.celebrate();this.addStat('hits',1,s);
    const ring=new Sprite(Gfx.circle(p.R,'rgba(0,0,0,0)','#ff0'),p.R*2,p.R*2);ring.blend='add';ring.x=p.tx;ring.y=p.ty;ring.z=30;s.field.add(ring);ring.run(A.sequence([A.group([A.scaleTo(2.2,.5),A.fadeOut(.5)]),A.remove()]))}
   else if(mine>0){s.floatText('+'+mine,pos,s.color,24);s.burst(pos,s.color,10);Sfx.play(mine>=3?'right':'pop');if(!s.isCPU)Haptic.tap('light')}
   else{s.floatText('DANEBEN',{x:pos.x,y:Math.max(pos.y,-s.h/2+60)},white(.8),14);Sfx.play('wrong')}}
  const bump=tot-p.prevTotal-mine;if(bump<0)s.floatText(''+bump,{x:p.tx,y:p.ty+p.R*.5},'#f00',16);this.setScore(s,tot);
  if(p.thrown>=MAXS){p.mode='done';this.updCounter(p);p.bear.stopBob();if(this.pads.every(o=>o.mode==='done'))this.finishAll()}else this.spawnStone(p)}
 finishAll(){if(this.finishing)return;this.finishing=true;this.run(A.sequence([A.wait(.5),A.run(()=>{for(const p of this.pads)this.setScore(p.seat,this.total(p));this.finishGame()})]))}
}
Arcade.register('curling',CurlingGame);
})();
