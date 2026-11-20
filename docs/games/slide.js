(()=>{
const {Node,Sprite,A,Gfx,Theme,rgba,white,label}=SK;
const DIRS=[[0,1],[0,-1],[-1,0],[1,0]];
function slide(lv,from,dir){const n=lv.n;let x=from%n,y=Math.floor(from/n);const d=DIRS[dir];
 while(true){const nx=x+d[0],ny=y+d[1];if(nx<0||ny<0||nx>=n||ny>=n||lv.rocks.has(ny*n+nx))break;x=nx;y=ny;const i=y*n+x;if(i===lv.goal)return{t:'goal',i};if(lv.holes.has(i))return{t:'hole',i}}
 return{t:'stop',i:y*n+x}}
function solve(lv,from){const prev=new Map([[from,[-1,-1]]]),q=[from];let qi=0;
 while(qi<q.length){const c=q[qi++];for(let d=0;d<4;d++){const o=slide(lv,c,d);if(o.t==='hole')continue;
  if(o.t==='goal'){const res=[d];let cur=c;while(true){const p=prev.get(cur);if(!p||p[0]<0)break;res.push(p[1]);cur=p[0]}return res.reverse()}
  if(!prev.has(o.i)){prev.set(o.i,[c,d]);q.push(o.i)}}}return null}
function makeLevel(r,n,no){const cells=n*n,want=Math.min(2+Math.floor(no/2),7);let best=null,bestLen=0;
 for(let k=0;k<250;k++){const all=r.shuffled([...Array(cells).keys()]),rc=Math.min(n+1+Math.floor(no/3),Math.floor(cells/3)),hc=Math.min(2+Math.floor(no/3),5);
  const lv={n,rocks:new Set(),holes:new Set(),start:all[0],goal:all[1]};for(let i=0;i<rc;i++)lv.rocks.add(all[2+i]);for(let i=0;i<hc;i++)lv.holes.add(all[2+rc+i]);
  const p=solve(lv,lv.start);if(p){if(p.length>=want)return lv;if(p.length>bestLen){bestLen=p.length;best=lv}}}
 return best||{n,rocks:new Set(),holes:new Set(),start:0,goal:n-1}}
const tileTex=s=>Gfx.texture('slide_ice_'+s,s,s,2,c=>{c.fillStyle='rgba(158,217,255,.28)';SK.rr(c,1,1,s-2,s-2,s*.15);c.fill();c.strokeStyle='rgba(179,242,255,.55)';c.lineWidth=1.2;SK.rr(c,1,1,s-2,s-2,s*.15);c.stroke();c.fillStyle='rgba(255,255,255,.1)';SK.rr(c,s*.1,s*.1,s*.5,s*.12,s*.05);c.fill()});
const rockTex=s=>Gfx.texture('slide_rock_'+s,s,s,2,c=>{c.fillStyle='rgb(82,82,82)';c.beginPath();c.arc(s/2,s/2,s*.42,0,7);c.fill();c.fillStyle='rgb(128,128,128)';c.beginPath();c.ellipse(s*.38,s*.38,s*.2,s*.2,0,0,7);c.fill();c.strokeStyle='rgb(38,38,38)';c.lineWidth=2;c.beginPath();c.arc(s/2,s/2,s*.42,0,7);c.stroke()});
const holeTex=s=>Gfx.texture('slide_hole_'+s,s,s,2,c=>{c.fillStyle='rgb(5,10,31)';c.beginPath();c.arc(s/2,s/2,s*.38,0,7);c.fill();c.strokeStyle='rgba(51,153,255,.9)';c.lineWidth=2.5;c.beginPath();c.arc(s/2,s/2,s*.38,0,7);c.stroke()});
class SlideGame extends MiniScene{
 setupGame(){this.duration=40;const wide=(this.seats[0]?this.seats[0].w:200)>260;this.gridN=wide?6:5;this.st=[];
  for(const s of this.seats){const g={rand:this.newRand(),levelNo:0,board:new Node(),pos:0,moving:false,swipe:null,cpuAt:0,path:[]};g.cell=Math.floor(Math.min((s.w-14)/this.gridN,(s.h-78)/this.gridN));const bw=g.cell*this.gridN;g.ox=-bw/2;g.oy=-s.h/2+30;this.st.push(g);this.newLevel(s,false);
   const hint=label('WISCHEN',Math.min(18,s.w*.085),'#fff');hint.y=-s.h/2+14;hint.z=60;s.field.add(hint);hint.run(A.sequence([A.wait(4.4),A.fadeOut(.4),A.remove()]))}}
 center(g,i){const n=g.level.n;return{x:g.ox+g.cell*(i%n+.5),y:g.oy+g.cell*(Math.floor(i/n)+.5)}}
 feet(g,i){const c=this.center(g,i);return{x:c.x,y:c.y-g.cell*.38}}
 newLevel(s,animate){const g=this.st[s.index];g.board.removeFromParent();g.board=new Node();s.field.add(g.board);g.level=makeLevel(g.rand,this.gridN,g.levelNo);g.levelNo++;const lv=g.level,c=g.cell;
  for(let i=0;i<lv.n*lv.n;i++){const ctr=this.center(g,i),t=new Sprite(tileTex(c),c,c);t.x=ctr.x;t.y=ctr.y;g.board.add(t);
   if(lv.rocks.has(i)){const r=new Sprite(rockTex(c),c,c);r.x=ctr.x;r.y=ctr.y;r.z=2;g.board.add(r)}else if(lv.holes.has(i)){const h=new Sprite(holeTex(c),c,c);h.x=ctr.x;h.y=ctr.y;h.z=1;g.board.add(h);h.run(A.forever(A.sequence([A.scaleTo(.9,.8),A.scaleTo(1,.8)])))}}
  const gc=this.center(g,lv.goal),gl=new Sprite(Gfx.glow(),c*1.8,c*1.8);gl.color=Theme.orange;gl.cbf=1;gl.blend='add';gl.alpha=.7;gl.x=gc.x;gl.y=gc.y;gl.z=1;gl.run(A.forever(A.sequence([A.fadeTo(.3,.5),A.fadeTo(.8,.5)])));g.board.add(gl);
  const puck=new Sprite(Gfx.star(c*.36,Theme.orange),c*.72,c*.72);puck.x=gc.x;puck.y=gc.y;puck.z=2;puck.run(A.forever(A.rotateBy(Math.PI*2,3)));g.board.add(puck);
  g.bear=this.makeBear(s,c*.82,true);g.bear.z=10;g.board.add(g.bear);this.place(s,lv.start);
  if(animate){g.board.alpha=0;g.board.run(A.fadeIn(.25))}this.planCPU(s)}
 place(s,i){const g=this.st[s.index];g.pos=i;g.bear.removeAllActions();g.bear.setScale(1);g.bear.alpha=1;g.bear.rot=0;const f=this.feet(g,i);g.bear.x=f.x;g.bear.y=f.y;g.moving=false}
 planCPU(s){if(!s.isCPU)return;const g=this.st[s.index];g.path=solve(g.level,g.pos)||[];g.cpuAt=this.elapsed+.5+(1-s.skill)*1.3+Math.random()*.4}
 move(s,dir){const g=this.st[s.index];if(g.moving||!s.alive)return;const out=slide(g.level,g.pos,dir),target=out.i;
  if(target===g.pos){g.bear.squash();Sfx.play('tap');if(!s.isCPU)Haptic.tap('light');return}
  const d=DIRS[dir];if(d[0]!==0)g.bear.setFacing(d[0]>0);const n=g.level.n,dist=Math.abs(target%n-g.pos%n)+Math.abs(Math.floor(target/n)-Math.floor(g.pos/n)),dur=.06+.055*dist;
  g.moving=true;g.pos=target;Sfx.play('jump');
  // Eis-Spur (Extra: mehrere Schneeflocken entlang des Wegs)
  const tr=new Sprite(Gfx.glow(),g.cell*1.2,g.cell*1.2);tr.color=Theme.blue;tr.cbf=1;tr.blend='add';tr.alpha=.5;tr.x=g.bear.x;tr.y=g.bear.y;tr.z=5;g.board.add(tr);tr.run(A.sequence([A.fadeOut(.4),A.remove()]));
  const f=this.feet(g,target),steps=Math.max(2,dist*2);for(let k=0;k<steps;k++){const q=new Sprite(Gfx.dot(),5,5);q.blend='add';q.alpha=.6;q.x=g.bear.x;q.y=g.bear.y;q.z=4;g.board.add(q);q.run(A.sequence([A.wait(dur*k/steps),A.group([A.fadeOut(.45),A.scaleTo(.2,.45)]),A.remove()]));q.x=g.bear.x+(f.x-g.bear.x)*k/steps;q.y=g.bear.y+(f.y-g.bear.y)*k/steps}
  g.bear.run(A.sequence([SK.easeOut(A.moveTo(f.x,f.y,dur)),A.run(()=>this.arrived(s,out))]))}
 arrived(s,out){const g=this.st[s.index];g.moving=false;const p=this.center(g,g.pos);
  if(out.t==='goal'){this.addScore(s,1);this.addStat('goals',1,s);s.floatText('+1',p,Theme.orange,26);s.burst(p,Theme.orange,24,140);s.flash('#ff0',.12);Sfx.play('coin');if(!s.isCPU)Haptic.good();g.moving=true;g.bear.celebrate();g.bear.run(A.sequence([A.wait(.55),A.run(()=>this.newLevel(s,true))]))}
  else if(out.t==='hole'){s.burst(p,Theme.blue,14,90);s.flash('#00f',.25);Sfx.play('miss');if(!s.isCPU)Haptic.bad();g.moving=true;g.bear.run(A.sequence([A.group([A.scaleTo(.05,.3),A.rotateBy(4,.3)]),A.run(()=>this.resetBear(s))]))}
  else{g.bear.squash();Sfx.play('tap');if(!s.isCPU)Haptic.tap('light');
   if(!solve(g.level,g.pos)){s.floatText('NEU',p,'#fff',18);g.moving=true;g.bear.run(A.sequence([A.wait(.35),A.fadeOut(.12),A.run(()=>this.resetBear(s))]))}else this.planCPU(s)}}
 resetBear(s){const g=this.st[s.index];this.place(s,g.level.start);g.bear.alpha=0;g.bear.run(A.fadeIn(.2));this.planCPU(s)}
 gameUpdate(dt){for(const s of this.seats){if(!s.isCPU)continue;const g=this.st[s.index];if(g.moving||this.elapsed<g.cpuAt||!g.path.length)continue;let d=g.path.shift();if(Math.random()<(1-s.skill)*.12)d=Math.floor(Math.random()*4);this.move(s,d);g.cpuAt=this.elapsed+.25+(1-s.skill)*.7+Math.random()*.2}}
 began(seat,at){this.st[seat.index].swipe={x:at.x,y:at.y}}
 moved(seat,at){const g=this.st[seat.index],a=g.swipe;if(!a)return;const dx=at.x-a.x,dy=at.y-a.y;if(Math.hypot(dx,dy)<18)return;g.swipe=null;this.move(seat,Math.abs(dx)>Math.abs(dy)?(dx>0?3:2):(dy>0?0:1))}
 ended(seat){this.st[seat.index].swipe=null}
}
Arcade.register('slide',SlideGame);
})();
