(()=>{const {Node,Sprite,A,Gfx,rgba,white,label}=SK;
const DIRS=[{x:1,y:0},{x:0,y:1},{x:-1,y:0},{x:0,y:-1}];
class SnakeGame extends MiniScene{
 setupGame(){this.duration=60;this.st=this.seats.map(s=>{const p=NK.panel(s,s.color),cols=11,cell=Math.floor((p.w-14)/cols),rows=Math.floor((p.h-14)/cell),st={p,cols,rows,cell,ox:-cols*cell/2,oy:p.cy-rows*cell/2,body:[],dir:{x:1,y:0},ndir:{x:1,y:0},t:0,food:null,lives:3,pool:[],hearts:[],start:null,cpu:0,dead:0};
  const gr=new Sprite(Gfx.rect(cols*cell,rows*cell,white(1,.04),8),cols*cell,rows*cell);gr.y=p.cy;gr.z=-3;s.field.add(gr);
  st.food=new Sprite(Gfx.circle(cell*.4,'#fff','#ffd61a'),cell*.8,cell*.8);st.food.z=6;s.field.add(st.food);st.food.run(A.forever(A.sequence([A.scaleTo(1.2,.3),A.scaleTo(.9,.3)])));
  for(let i=0;i<3;i++){const h=label('♥',14,s.color);h.x=p.w/2-14-i*16;h.y=p.cy+p.h/2-10;h.z=9;s.field.add(h);st.hearts.push(h)}
  if(!s.isCPU){const h=label('WISCHEN = LENKEN',12,white(1,.7));h.y=p.cy+p.h/2-10;h.z=9;s.field.add(h);h.run(A.sequence([A.wait(5),A.fadeOut(.5),A.remove()]))}
  this.rst(s,st);return st})}
 cpos(st,c){return{x:st.ox+(c.x+.5)*st.cell,y:st.oy+(c.y+.5)*st.cell}}
 rst(s,st){st.body=[{x:5,y:Math.floor(st.rows/2)},{x:4,y:Math.floor(st.rows/2)},{x:3,y:Math.floor(st.rows/2)}];st.dir={x:1,y:0};st.ndir={x:1,y:0};this.feed(st);this.rdr(s,st)}
 feed(st){for(let k=0;k<50;k++){const c={x:Math.floor(Math.random()*st.cols),y:Math.floor(Math.random()*st.rows)};if(!st.body.some(b=>b.x===c.x&&b.y===c.y)){st.fc=c;const p=this.cpos(st,c);st.food.x=p.x;st.food.y=p.y;return}}}
 rdr(s,st){while(st.pool.length<st.body.length){const q=new Sprite(Gfx.pill(st.cell-2,st.cell-2,s.color,null,(st.cell-2)/2.6,false),st.cell-2,st.cell-2);q.z=5;s.field.add(q);st.pool.push(q)}
  st.pool.forEach((q,i)=>{if(i<st.body.length){const p=this.cpos(st,st.body[i]);q.x=p.x;q.y=p.y;q.hidden=false;q.alpha=i===0?1:.9-i*.01;q.color=i===0?'#fff':s.color;q.cbf=i===0?.35:0}else q.hidden=true})}
 gameUpdate(dt){for(const s of this.seats){const st=this.st[s.index];if(st.lives<=0)continue;st.t+=dt;const iv=Math.max(.09,.2-st.body.length*.003);if(st.t<iv)continue;st.t-=iv;
  if(s.isCPU)this.think(s,st);st.dir=st.ndir;const h=st.body[0],n={x:h.x+st.dir.x,y:h.y+st.dir.y};
  if(n.x<0||n.y<0||n.x>=st.cols||n.y>=st.rows||st.body.slice(0,-1).some(b=>b.x===n.x&&b.y===n.y)){st.lives--;if(st.hearts[st.lives])st.hearts[st.lives].alpha=.2;Sfx.play('wrong');s.flash('#f00',.3);s.shake(5);const hp=this.cpos(st,h);s.burst(hp,s.color,14,120);
   if(st.lives<=0){s.knockOut('RAUS');st.body=[];this.rdr(s,st);if(this.seats.every(o=>this.st[o.index].lives<=0))this.finishGame()}else this.rst(s,st);continue}
  st.body.unshift(n);if(n.x===st.fc.x&&n.y===st.fc.y){this.addScore(s,1);this.addStat('hits',1,s);const p=this.cpos(st,n);s.floatText('+1',p,s.color,18);s.burst(p,'#ffd61a',8,80);Sfx.play('pop');this.feed(st)}else st.body.pop();this.rdr(s,st)}}
 think(s,st){const h=st.body[0];let best=null,bs=-1e9;for(const d of DIRS){if(d.x===-st.dir.x&&d.y===-st.dir.y&&st.body.length>1)continue;const n={x:h.x+d.x,y:h.y+d.y};if(n.x<0||n.y<0||n.x>=st.cols||n.y>=st.rows||st.body.slice(0,-1).some(b=>b.x===n.x&&b.y===n.y))continue;let sc=-Math.abs(n.x-st.fc.x)-Math.abs(n.y-st.fc.y)+Math.random()*(1-s.skill)*6;const nx={x:n.x+d.x,y:n.y+d.y};if(nx.x<0||nx.y<0||nx.x>=st.cols||nx.y>=st.rows)sc-=3;if(sc>bs){bs=sc;best=d}}if(best)st.ndir=best}
 began(s,at){this.st[s.index].start={x:at.x,y:at.y}}
 moved(s,at){const st=this.st[s.index];if(!st.start)return;const dx=at.x-st.start.x,dy=at.y-st.start.y;if(Math.hypot(dx,dy)<16)return;const d=Math.abs(dx)>Math.abs(dy)?{x:Math.sign(dx),y:0}:{x:0,y:Math.sign(dy)};if(!(d.x===-st.dir.x&&d.y===-st.dir.y))st.ndir=d;st.start={x:at.x,y:at.y}}
 ended(s){this.st[s.index].start=null}
}
Arcade.register('snake',SnakeGame);})();
