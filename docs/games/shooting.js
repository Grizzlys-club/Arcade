(()=>{const {Node,Sprite,A,Gfx,rgba,white,label}=SK;
class ShootingGame extends MiniScene{
 setupGame(){this.duration=40;this.st=this.seats.map(s=>{const p=NK.panel(s,s.color),st={p,targets:[],spawn:.3,cpu:1+Math.random(),combo:0};
  const g=new Sprite(Gfx.pill(p.w-40,3,white(1,.25),null,2,false),p.w-40,3);g.y=p.cy-p.h/2+34;g.z=-4;s.field.add(g);
  const pk=new Sprite(Gfx.circle(11,white(.1),'#fff'),22,22);pk.y=p.cy-p.h/2+22;pk.z=3;s.field.add(pk);st.base=pk;
  if(!s.isCPU){const h=label('TIPPE AUF DIE ZIELE',12,white(1,.7));h.y=p.cy-p.h/2+52;h.z=9;s.field.add(h);h.run(A.sequence([A.wait(5),A.fadeOut(.5),A.remove()]))}return st})}
 tex(k){return Gfx.texture('shoot_'+k,64,64,2,c=>{const cols=k==='gold'?['#ffd61a','#fff','#ffd61a','#fff']:k==='bad'?['#ff3b3b','#fff','#ff3b3b','#fff']:['#ff6a00','#fff','#ff6a00','#fff'];[30,22,14,6].forEach((r,i)=>{c.fillStyle=cols[i];c.beginPath();c.arc(32,32,r,0,7);c.fill()});c.strokeStyle='rgba(0,0,0,.5)';c.lineWidth=2;c.beginPath();c.arc(32,32,30,0,7);c.stroke()})}
 gameUpdate(dt){const t=this.elapsed/this.duration;for(const s of this.seats){const st=this.st[s.index],p=st.p;st.spawn-=dt;
  if(st.spawn<=0){st.spawn=NK.rr(.55,.95)-.3*t;const r=Math.random(),kind=r<.12?'gold':r<.28?'bad':'norm',rad=kind==='gold'?14:kind==='bad'?20:NK.rr(18,26),row=Math.floor(Math.random()*3),y=p.cy+p.h/2-70-row*(p.h-170)/2,dir=Math.random()<.5?1:-1,sp=(kind==='gold'?200:110)*NK.rr(.8,1.3)*(1+t*.6);
   const n=new Sprite(this.tex(kind),rad*2,rad*2);n.x=-dir*(p.w/2+rad);n.y=y;n.z=5;s.field.add(n);st.targets.push({n,vx:dir*sp,r:rad,kind,y});n.run(A.forever(A.sequence([A.scaleTo(1.08,.3),A.scaleTo(.94,.3)])))}
  for(const q of st.targets){q.n.x+=q.vx*dt;q.n.y=q.y+Math.sin(this.elapsed*3+q.r)*6;if(Math.abs(q.n.x)>p.w/2+q.r+4)q.dead=true}
  st.targets=st.targets.filter(q=>{if(q.dead)q.n.run(A.remove());return!q.dead});
  if(s.isCPU){st.cpu-=dt;if(st.cpu<=0){st.cpu=NK.rr(.5,1.1)+(1-s.skill)*.8;const c=st.targets.filter(q=>q.kind!=='bad'&&Math.abs(q.n.x)<p.w/2-10);if(c.length){const q=c[Math.floor(Math.random()*c.length)];const e=(1-s.skill)*40;this.fire(s,{x:q.n.x+NK.rr(-e,e),y:q.n.y+NK.rr(-e,e)})}}}}}
 began(s,at){this.fire(s,at)}
 fire(s,pt){const st=this.st[s.index],b=NK.dot(s,'#fff',10,12);b.x=st.base.x;b.y=st.base.y;b.run(A.sequence([A.moveTo(pt.x,pt.y,.08),A.remove()]));
  let best=null,bd=1e9;for(const q of st.targets){const d=Math.hypot(q.n.x-pt.x,q.n.y-pt.y);if(d<q.r+12&&d<bd){bd=d;best=q}}
  if(!best){st.combo=0;Sfx.play('tap');return}
  const q=best;st.targets=st.targets.filter(o=>o!==q);const pos={x:q.n.x,y:q.n.y};q.n.run(A.sequence([A.group([A.scaleTo(1.6,.15),A.fadeOut(.15)]),A.remove()]));
  if(q.kind==='bad'){this.addScore(s,-2);st.combo=0;s.floatText('−2',pos,'#f44',20);Sfx.play('wrong');s.flash('#f00',.25);s.shake(4)}
  else{st.combo++;const pts=(q.kind==='gold'?3:1)+(st.combo>=3?1:0);this.addScore(s,pts);this.addStat('hits',1,s);s.floatText('+'+pts,pos,q.kind==='gold'?'#ff0':s.color,22);s.burst(pos,q.kind==='gold'?'#ff0':s.color,10,90);NK.ring(s,pos,q.kind==='gold'?'#ff0':s.color,10);Sfx.play(q.kind==='gold'?'coin':'pop');if(!s.isCPU)Haptic.tap('light');
   if(st.combo===3){s.banner('COMBO!','#ff0',22,.5)}}}
}
Arcade.register('shooting',ShootingGame);})();
