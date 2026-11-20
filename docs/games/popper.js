(()=>{const {Node,Sprite,A,Gfx,rgba,white,label}=SK;
class PopperGame extends MiniScene{
 setupGame(){this.duration=30;this.st=this.seats.map(s=>{const p=NK.panel(s,s.color),st={p,b:[],spawn:.3,cpu:1};if(!s.isCPU){const h=label('TIPPE DIE BALLONS',12,white(1,.7));h.y=p.cy-p.h/2+18;h.z=9;s.field.add(h);h.run(A.sequence([A.wait(5),A.fadeOut(.5),A.remove()]))}return st})}
 tex(k,col){return Gfx.texture('balloon_'+k+col,48,64,2,c=>{c.fillStyle=k==='bomb'?'#222':col;c.beginPath();c.ellipse(24,26,20,24,0,0,7);c.fill();c.fillStyle='rgba(255,255,255,.35)';c.beginPath();c.ellipse(16,16,5,8,-.5,0,7);c.fill();c.strokeStyle='rgba(255,255,255,.5)';c.lineWidth=1.5;c.beginPath();c.moveTo(24,50);c.quadraticCurveTo(18,57,24,63);c.stroke();if(k==='bomb'){c.fillStyle='#f33';c.font='bold 22px sans-serif';c.textAlign='center';c.fillText('✕',24,34)}if(k==='gold'){c.fillStyle='#fff';c.font='bold 18px sans-serif';c.textAlign='center';c.fillText('★',24,32)}})}
 gameUpdate(dt){const t=this.elapsed/this.duration;for(const s of this.seats){const st=this.st[s.index],p=st.p;st.spawn-=dt;
  if(st.spawn<=0){st.spawn=NK.rr(.28,.55)*(1-t*.35);const r=Math.random(),k=r<.1?'gold':r<.24?'bomb':'norm',cols=['#ff6a00','#40ccff','#ff4db3','#40ff73','#b07cff'],col=k==='gold'?'#ffd61a':cols[Math.floor(Math.random()*5)];
   const n=new Sprite(this.tex(k,col),44,58);n.x=NK.rr(-p.w/2+30,p.w/2-30);n.y=p.cy-p.h/2-34;n.z=5;s.field.add(n);st.b.push({n,k,col,v:NK.rr(80,130)*(k==='gold'?1.5:1)*(1+t*.8),ph:Math.random()*6,x0:n.x})}
  for(const b of st.b){b.n.y+=b.v*dt;b.n.x=b.x0+Math.sin(this.elapsed*2+b.ph)*10;if(b.n.y>p.cy+p.h/2+40)b.dead=true}
  st.b=st.b.filter(b=>{if(b.dead)b.n.run(A.remove());return!b.dead});
  if(s.isCPU){st.cpu-=dt;if(st.cpu<=0){st.cpu=NK.rr(.3,.7)+(1-s.skill)*.7;const c=st.b.filter(b=>b.k!=='bomb'&&b.n.y>p.cy-p.h/2+20);if(c.length){const q=c[Math.floor(Math.random()*c.length)],e=(1-s.skill)*36;this.hit(s,{x:q.n.x+NK.rr(-e,e),y:q.n.y+NK.rr(-e,e)})}}}}}
 began(s,at){this.hit(s,at)}
 hit(s,pt){const st=this.st[s.index];let best=null,bd=1e9;for(const b of st.b){const d=Math.hypot(b.n.x-pt.x,(b.n.y-pt.y)*.8);if(d<30&&d<bd){bd=d;best=b}}if(!best){Sfx.play('tap');return}
  const b=best;st.b=st.b.filter(o=>o!==b);const pos={x:b.n.x,y:b.n.y};b.n.run(A.sequence([A.group([A.scaleTo(1.5,.12),A.fadeOut(.12)]),A.remove()]));
  if(b.k==='bomb'){this.addScore(s,-3);s.floatText('−3',pos,'#f44',24);s.burst(pos,'#f33',16,140);s.flash('#f00',.3);s.shake(6);Sfx.play('wrong')}
  else{const pts=b.k==='gold'?3:1;this.addScore(s,pts);this.addStat('hits',1,s);s.floatText('+'+pts,pos,b.k==='gold'?'#ff0':b.col,22);s.burst(pos,b.col,b.k==='gold'?18:10,110);NK.ring(s,pos,b.col,12,.3);Sfx.play(b.k==='gold'?'coin':'pop');if(!s.isCPU)Haptic.tap('light')}}
}
Arcade.register('popper',PopperGame);})();
